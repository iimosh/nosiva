// Applies neon/migrations/*.sql to the Neon database, in name order, each in
// its own transaction, and remembers which ones ran (table
// public._migrations) so running it again only applies new files.
//
//   npm run migrate              apply pending migrations
//   npm run migrate -- --sql "select 1"   run one statement and print rows
//
// Reads DATABASE_URL_UNPOOLED from .env.local (written by `neon deploy`).
// After applying new migrations it refreshes the Data API's schema cache,
// so new tables and functions are callable from the app straight away.
// The connection string is never printed.
import { execSync } from "node:child_process";
import { readFileSync, readdirSync } from "node:fs";
import { dirname, join } from "node:path";
import { fileURLToPath } from "node:url";
import pg from "pg";

const root = join(dirname(fileURLToPath(import.meta.url)), "..");

function loadEnv() {
  const env = {};
  for (const line of readFileSync(join(root, ".env.local"), "utf8").split(/\r?\n/)) {
    const m = line.match(/^\s*([A-Z0-9_]+)\s*=\s*(.*)\s*$/);
    if (m) env[m[1]] = m[2].replace(/^["']|["']$/g, "");
  }
  return env;
}

const env = loadEnv();
const url = env.DATABASE_URL_UNPOOLED ?? env.DATABASE_URL;
if (!url) throw new Error("DATABASE_URL missing from .env.local — run `neon deploy`");

// verify-full: the strictest TLS check (and silences pg's sslmode warning).
const client = new pg.Client({
  connectionString: url.replace(/sslmode=(require|prefer|verify-ca)/, "sslmode=verify-full"),
});
await client.connect();

try {
  const sqlIndex = process.argv.indexOf("--sql");
  if (sqlIndex !== -1) {
    const res = await client.query(process.argv[sqlIndex + 1]);
    const results = Array.isArray(res) ? res : [res];
    for (const r of results) if (r.rows?.length) console.table(r.rows);
    process.exit(0);
  }

  await client.query(`create table if not exists public._migrations (
    name text primary key,
    applied_at timestamptz not null default now()
  )`);
  await client.query("revoke all on public._migrations from public");

  const done = new Set(
    (await client.query("select name from public._migrations")).rows.map((r) => r.name),
  );
  const files = readdirSync(join(root, "migrations"))
    .filter((f) => f.endsWith(".sql"))
    .sort();

  let applied = 0;
  for (const file of files) {
    if (done.has(file)) continue;
    const sql = readFileSync(join(root, "migrations", file), "utf8");
    process.stdout.write(`→ ${file} … `);
    try {
      await client.query("begin");
      await client.query(sql);
      await client.query("insert into public._migrations (name) values ($1)", [file]);
      await client.query("commit");
      applied++;
      console.log("ok");
    } catch (e) {
      await client.query("rollback");
      console.log("FAILED");
      console.error(`  ${e.message}${e.position ? ` (at character ${e.position})` : ""}`);
      if (e.where) console.error(`  where: ${e.where}`);
      process.exit(1);
    }
  }
  // The Data API keeps a cached list of tables and functions: new ones are
  // only callable from the app after a refresh.
  if (applied > 0) {
    process.stdout.write("→ refreshing the Data API schema cache … ");
    execSync("neon data-api refresh-schema --no-color", { cwd: root, stdio: "ignore" });
    console.log("ok");
  }
  console.log("Database is up to date.");
} finally {
  await client.end();
}
