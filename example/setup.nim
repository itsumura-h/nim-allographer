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
    table("user",[
      Column.increments("id"),
      Column.string("name").nullable(),
      Column.string("email").nullable(),
      Column.foreign("auth_id").reference("id").onTable("auth").onDelete(SET_NULL)
    ])
  )

  # seeder
  seeder(rdb, "auth"):
    rdb.table("auth").insert(@[
      %*{"auth": "admin"},
      %*{"auth": "user"}
    ])
    .waitFor

  seeder(rdb, "user"):
    var user: seq[JsonNode]
    for i in 1..10:
      let authId = if i mod 2 == 0: 2 else: 1
      user.add(
        %*{
          "name": &"user{i}",
          "email": &"user{i}@mail.com",
          "auth_id": authId
        }
      )

    rdb.table("user").insert(user).waitFor
