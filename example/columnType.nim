import json

import ../src/allographer/QueryBuilder
import ../src/allographer/SchemaBuilder

echo RDB().table("users").select("id", "name", "address")
    .limit(2).get()

echo RDB().table("users").select("id", "name", "address")
    .first()

echo RDB().table("users")
    .select("id", "name", "address")
    .find(3)

Schema().create([
  Table().create("sample", [
    Column().increments("id"),
    Column().float("float"),
    Column().string("string"),
    Column().datetime("datetime"),
    Column().string("'null'").nullable(),
    Column().boolean("is_admin")
  ], isRebuild=true)
])

RDB().table("sample").insert(%*{
  "id": 1,
  "float": 3.14,
  "string": "string",
  "datetime": "2019-01-01 12:00:00.1234",
  "is_admin": true
}).exec()

echo RDB().table("sample")
  .select("id", "float", "string", "datetime", "null", "is_admin")
  .get()