discard """
  cmd: "nim c -d:reset -r $file"
"""

import
  std/unittest,
  std/json,
  std/strformat,
  std/strutils,
  std/options,
  std/asyncdispatch,
  ../src/allographer/schema_builder,
  ../src/allographer/query_builder,
  ./connections


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
  seeder rdb, "auth":
    rdb.table("auth").insert(@[
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


for rdb in dbConnections:
  block:
    setup(rdb)
    asyncBlock:
      var user = rdb.table("users").get().await
      echo user
      check true

  block:
    setup(rdb)
    asyncBlock:
      transaction rdb:
        var user = rdb.table("users").select("id").where("name", "=", "user3").first.await.get
        var id = user["id"].getInt()
        check id == 3
        user = rdb.table("users").select("name", "email").find(id).await.get
        check user == %*{"name":"user3","email":"user3@gmail.com"}

  block:
    asyncBlock:
      try:
        rdb.raw("BEGIN").exec().await
        rdb.table("users").insert(%*{"id": 9, "name": "user9", "email": "user9@example.com"}).await
        rdb.raw("COMMIT").exec().await
        check false
      except:
        echo "=== rollback"
        echo getCurrentExceptionMsg()
        rdb.raw("ROLLBACK").exec().await
        check true

  block:
    setup(rdb)
    asyncBlock:
      transaction rdb:
        rdb.table("users").insert(%*{"id": 9, "name": "user9", "email": "user9@example.com"}).await
        check false
      check true

  block:
    setup(rdb)
    asyncBlock:
      var id:int
      transaction rdb:
        id = rdb.table("users")
                  .insertId(%*{"name": "user11", "email": "user11@example.com"})
                  .await
        echo id
      check rdb.table("users").max("id").await.get == $id

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
      check rdb.table("users").where("id", ">", 10).get().await.len == 0
