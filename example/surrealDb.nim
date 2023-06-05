import std/asyncdispatch
import std/json
import ../src/allographer/connection
import ../src/allographer/query_builder


let db = dbOpen(SurrealDB, "test:test", "user", "pass", "http://surreal", 8000, 10, 30, true, true)
db.raw("DELETE FROM account").exec().waitFor
echo db.raw("INFO FOR DB").get().waitFor

for _ in 0..3:
  db.raw("CREATE account SET name = 'ACME Inc', created_at = time::now()").exec().waitFor

let resp = db.raw("SELECT * from account").get().waitFor
for row in resp:
  echo row
  echo row["id"].getStr
