// Saves the Firebase service-account key for the push function into the
// git-ignored .env.secrets, as the single line of JSON a .env file needs.
// The key is never printed.
//
//   npm run save-fcm-key -- "C:\path\to\nosiva-firebase-adminsdk-xxxx.json"
import { existsSync, readFileSync, writeFileSync } from "node:fs";
import { dirname, join } from "node:path";
import { fileURLToPath } from "node:url";

const file = process.argv[2];
if (!file) {
  console.error('Usage: npm run save-fcm-key -- "<path to the key .json>"');
  process.exit(1);
}
const key = JSON.parse(readFileSync(file, "utf8"));
for (const field of ["project_id", "client_email", "private_key"]) {
  if (!key[field]) {
    console.error(`That file has no "${field}" — is it the Firebase service-account key?`);
    process.exit(1);
  }
}

const target = join(dirname(fileURLToPath(import.meta.url)), "..", ".env.secrets");
const others = existsSync(target)
  ? readFileSync(target, "utf8").split(/\r?\n/).filter((l) => l && !l.startsWith("FCM_SERVICE_ACCOUNT="))
  : [];
// Single quotes keep the JSON's double quotes and \n sequences as they are.
writeFileSync(target, [...others, `FCM_SERVICE_ACCOUNT='${JSON.stringify(key)}'`, ""].join("\n"));
console.log(`Saved the key for Firebase project "${key.project_id}" to .env.secrets.`);
