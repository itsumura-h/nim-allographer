discard """
  cmd: "nim c -d:reset -r $file"
"""

import unittest, json, strformat, options, asyncdispatch
import ../src/allographer/schema_builder
import ../src/allographer/query_builder
import connections


proc setup(rdb:Rdb) =
  rdb.create([
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
  ])

  # seeder
  asyncBlock:
    rdb.table("auth").insert(@[
      %*{"auth": "admin"},
      %*{"auth": "user"}
    ])
    .await

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

    rdb.table("users").insert(users).await


for rdb in dbConnections:
  block:
    setup(rdb)
    asyncBlock:
      try:
        var user = rdb.table("users").get().await
        echo user
      except:
        discard

  block:
    setup(rdb)
    asyncBlock:
      transaction rdb:
        var user = rdb.table("users").select("id").where("name", "=", "user3").first.await.get
        var id = user["id"].getInt()
        echo id
        user = rdb.table("users").select("name", "email").find(id).await.get
        echo user

  block:
    waitFor (proc(){.async.}=
      try:
        rdb.raw("BEGIN").exec().await
        rdb.table("users").insert(%*{"id": 9, "name": "user9", "email": "user9@example.com"}).await
        rdb.raw("COMMIT").exec().await
      except:
        echo "=== rollback"
        echo getCurrentExceptionMsg()
        rdb.raw("ROLLBACK").exec().await

      echo rdb.table("users").find(11).await
    )()

  block:
    setup(rdb)
    asyncBlock:
      transaction rdb:
        echo "=== in transaction"
        rdb.table("users").insert(%*{"id": 9, "name": "user9", "email": "user9@example.com"}).await
        echo "=== end of transaction"
      echo "=== out of transaction"
      echo rdb.table("users").find(11).await

  block:
    setup(rdb)
    asyncBlock:
      transaction rdb:
        let id = rdb.table("users")
                  .insertId(%*{"name": "user11", "email": "user11@example.com"})
                  .await
        echo id
      echo rdb.table("users").max("id").await

  block:
    setup(rdb)
    asyncBlock:
      transaction rdb:
        let id = rdb.table("users")
                  .insertId(@[
                    %*{"name": "user11", "email": "user11@example.com"},
                    %*{"name": "user12", "email": "user12@example.com"}
                  ])
                  .await
        echo id
      echo rdb.table("users").max("id").await

  block:
    setup(rdb)
    asyncBlock:
      transaction rdb:
        discard rdb.table("users").insertsID(
          @[
            %*{"name": "John", "email": "John@gmail.com", "address": "London"},
            %*{"name": "Paul", "email": "Paul@gmail.com", "address": "London"},
            %*{"name": "George", "birth_date": "1943-02-25", "address": "London"},
          ]
        )
        .await
      echo rdb.table("users").where("id", ">", 10).get().await
