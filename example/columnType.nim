import json, asyncdispatch

import ../src/allographer/query_builder
import ../src/allographer/schema_builder
import ./connections

asyncBlock:
  rdb.schema([
    table("auth",[
      Column().increments("id"),
      Column().string("auth")
    ]),
    table("users",[
      Column().increments("id"),
      Column().string("name").nullable(),
      Column().string("email").nullable(),
      Column().string("password").nullable(),
      Column().string("address").nullable(),
      Column().date("birth_date").nullable(),
      Column().foreign("auth_id").reference("id").on("auth").onDelete(SET_NULL)
    ]),
    table("sample", [
      Column().increments("id"),
      Column().float("float"),
      Column().string("string"),
      Column().datetime("datetime"),
      Column().string("null").nullable(),
      Column().boolean("is_admin")
    ])
  ])

  echo repr await rdb.table("users").select("id", "name", "address")
      .limit(2)
      .get()

  echo await rdb.table("users").select("id", "name", "address").first()

  echo await rdb.table("users")
      .select("id", "name", "address")
      .find(3)

  await rdb.table("sample").insert(%*{
    "id": 1,
    "float": 3.14,
    "string": "string",
    "datetime": "2019-01-01 12:00:00.1234",
    "is_admin": true
  })

  echo await rdb.table("sample")
    .select("id", "float", "string", "datetime", "null", "is_admin")
    .get()

  echo await rdb.table("sample")
    .select("id", "float", "string", "datetime", "null", "is_admin")
    .get()


  var sql = "update users set name='John' where id = 1"
  await rdb.raw(sql).exec()

  sql = "select * from users where id = 1"
  echo await rdb.raw(sql).getRaw()
