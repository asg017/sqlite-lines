import { Database } from "https://deno.land/x/sqlite3/mod.ts";
import * as sqlite_lines from "https://deno.land/x/sqlite_lines/mod.ts";
import sqlite_lines_meta from "https://deno.land/x/sqlite_lines/deno.json" assert { type: "json" };

console.log(`sqlite_lines_meta version:`, sqlite_lines_meta.version);
``;
const db = new Database(":memory:");

db.enableLoadExtension = true;
sqlite_lines.load(db);

const [version] = db.prepare("select lines_version()").value<[string]>()!;

console.log(version);
