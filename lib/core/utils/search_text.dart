/// Makes typed text safe to use inside a "contains"/"matches" (ILIKE)
/// filter: characters that would act as wildcards (`%` any text, `_` any
/// single character) are matched literally instead, and characters that
/// have a meaning in the database API's filter syntax are dropped.
///
/// Without this, typing "%" as a colour would match every listing, and a
/// brand like "h_m" would match "ham", "hem", …
String likeLiteral(String input) => input
    .replaceAll(RegExp(r'[,()"*]'), '')
    .replaceAllMapped(RegExp(r'[\\%_]'), (m) => '\\${m[0]}')
    .trim();
