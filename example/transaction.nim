import json, asyncdispatch, strformat
import ../src/allographer/schema_builder
import ../src/allographer/query_builder
import ./connections
import ./setup


proc main(){.async.} =
  rdb.create(
    table("auth",[
      Column.increments("id"),
      Column.string("auth")
    ]),
    table("users",[
      Column.increments("id"),
      Column.string("name").nullable(),
      Column.string("email").nullable(),
      Column.string("address").nullable(),
      Column.foreign("auth_id").reference("id").on("auth").onDelete(SET_NULL)
    ])
  )

  # seeder
  seeder rdb, "auth":
    rdb.table("auth").inserts(@[
      %*{"auth": "admin"},
      %*{"auth": "user"}
    ])
    .waitFor

  seeder rdb, "users":
    var users: seq[JsonNode]
    for i in 1..10:
      let authId = if i mod 2 == 0: 2 else: 1
      users.add(
        %*{
          "name": &"user{i}",
          "email": &"user{i}@gmail.com",
          "auth_id": authId
        }
      )
    rdb.table("users").insert(users).waitFor

  echo "====="
  transaction rdb:
    echo rdb.table("users").select("name", "email").where("id", "=", 2).get().await

  echo "====="
  transaction rdb:
    rdb.table("table").insert(%*{"aaa": "bbb"}).await
    echo rdb.table("aaa").get().await

main().waitFor
