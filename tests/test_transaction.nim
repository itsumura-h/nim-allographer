discard """
  cmd: "nim c -d:reset -r $file"
"""

import unittest, json, strformat, options, asyncdispatch
import ../src/allographer/schema_builder
import ../src/allographer/query_builder
import connections

proc setup() =
  rdb.schema([
    table("auth",[
      Column().increments("id"),
      Column().string("auth")
    ], reset=true),
    table("users",[
      Column().increments("id"),
      Column().string("name").nullable(),
      Column().string("email").nullable(),
      Column().string("address").nullable(),
      Column().foreign("auth_id").reference("id").on("auth").onDelete(SET_NULL)
    ], reset=true)
  ])

  # seeder
  asyncBlock:
    await rdb.table("auth").insert(@[
      %*{"auth": "admin"},
      %*{"auth": "user"}
    ])

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

    await rdb.table("users").insert(users)

block:
  setup()
  asyncBlock:
    try:
      var user = await rdb.table("users").get()
      echo user
    except:
      discard

block:
  setup()
  asyncBlock:
    transaction rdb:
      var user= await(rdb.table("users").select("id").where("name", "=", "user3").first).get
      var id = user["id"].getInt()
      echo id
      user = await(rdb.table("users").select("name", "email").find(id)).get
      echo user

block:
  waitFor (proc(){.async.}=
    try:
      await rdb.raw("BEGIN").exec()
      await rdb.table("users").insert(%*{"id": 9, "name": "user9", "email": "user9@example.com"})
      await rdb.raw("COMMIT").exec()
    except:
      echo "=== rollback"
      echo getCurrentExceptionMsg()
      await rdb.raw("ROLLBACK").exec()

    echo await rdb.table("users").find(11)
  )()

block:
  setup()
  asyncBlock:
    transaction rdb:
      echo "=== in transaction"
      await rdb.table("users").insert(%*{"id": 9, "name": "user9", "email": "user9@example.com"})
      echo "=== end of transaction"
    echo "=== out of transaction"
    echo await rdb.table("users").find(11)

block:
  setup()
  asyncBlock:
    transaction rdb:
      let id = await rdb.table("users")
                .insertId(%*{"name": "user11", "email": "user11@example.com"})
      echo id
    echo await rdb.table("users").max("id")

block:
  setup()
  asyncBlock:
    transaction rdb:
      let id = await rdb.table("users")
                .insertId(@[
                  %*{"name": "user11", "email": "user11@example.com"},
                  %*{"name": "user12", "email": "user12@example.com"}
                ])
      echo id
    echo await rdb.table("users").max("id")

block:
  setup()
  asyncBlock:
    transaction rdb:
      discard await rdb.table("users").insertsID(
        @[
          %*{"name": "John", "email": "John@gmail.com", "address": "London"},
          %*{"name": "Paul", "email": "Paul@gmail.com", "address": "London"},
          %*{"name": "George", "birth_date": "1943-02-25", "address": "London"},
        ]
      )
    echo await rdb.table("users").where("id", ">", 10).get()
