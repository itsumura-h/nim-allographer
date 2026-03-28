# nim c -r -d:reset example/columnType.nim
import std/json
import std/asyncdispatch
import ../src/allographer/query_builder
import ../src/allographer/schema_builder
import ./connections

asyncBlock:
  rdb.create([
    table("auth",[
      Column.increments("id"),
      Column.string("auth")
    ]),
    table("users",[
      Column.increments("id"),
      Column.string("name").nullable(),
      Column.string("email").nullable(),
      Column.string("password").nullable(),
      Column.string("address").nullable(),
      Column.date("birth_date").nullable(),
      Column.foreign("auth_id").reference("id").onTable("auth").onDelete(SET_NULL)
    ]),
    table("sample", [
      Column.increments("id"),
      Column.float("float"),
      Column.string("string"),
      Column.datetime("datetime"),
      Column.string("null").nullable(),
      Column.boolean("is_admin")
    ])
  ])

  echo await rdb.select("id", "name", "address").table("users")
      .limit(2)
      .get()

  echo await rdb.select("id", "name", "address").table("users").first()

  echo await rdb.select("id", "name", "address").table("users").find(3)

  await rdb.table("sample").insert(%*{
    "id": 1,
    "float": 3.14,
    "string": "string",
    "datetime": "2019-01-01 12:00:00.1234",
    "is_admin": true
  })

  echo await rdb.select("id", "float", "string", "datetime", "null", "is_admin").table("sample").get()

  echo await rdb.select("id", "float", "string", "datetime", "null", "is_admin").table("sample").get()


  var sql = "update users set name='John' where id = 1"
  await rdb.raw(sql).exec()

  sql = "select * from users where id = 1"
  echo await rdb.raw(sql).get()
