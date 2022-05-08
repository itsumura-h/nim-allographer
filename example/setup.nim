import
  std/strformat,
  std/json,
  std/asyncdispatch,
  ../src/allographer/query_builder,
  ../src/allographer/schema_builder

from ./connections import rdb

template bench*(msg, body) =
  block:
    echo "=== " & msg
    let start = cpuTime()
    body
    echo cpuTime() - start

proc setup*() =
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
