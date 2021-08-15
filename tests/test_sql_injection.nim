import unittest, json, strformat, asyncdispatch
import ../src/allographer/schema_builder
import ../src/allographer/query_builder
import connections


suite "sql injection":
  setup:
    rdb.schema([
      table("auth",[
        Column().increments("id"),
        Column().string("auth")
      ], reset=true),
      table("users",[
        Column().increments("id"),
        Column().string("name").nullable(),
        Column().string("email").nullable(),
        Column().string("password").nullable(),
        Column().string("salt").nullable(),
        Column().string("address").nullable(),
        Column().date("birth_date").nullable(),
        Column().foreign("auth_id").reference("id").on("auth").onDelete(SET_NULL)
      ], reset=true)
    ])

    # シーダー
    asyncBlock:
      await rdb.table("auth").insert(@[
        %*{"auth": "admin"},
        %*{"auth": "user"}
      ])
      var insertData: seq[JsonNode]
      for i in 1..100:
        let authId = if i mod 2 == 0: 1 else: 2
        insertData.add(
          %*{
            "name": &"user{i}",
            "email": &"user{i}@gmail.com",
            "auth_id": authId
          }
        )
      await rdb.table("users").insert(insertData)

  test "1":
    asyncBlock:
      var x = await rdb.table("users").where("name", "=", "user1").get()
      var y = await rdb.table("users").where("name", "=", "user1' AND 'A' = 'A").get()
      echo x
      echo y
      check x != y
  test "2":
    asyncBlock:
      var x = await rdb.table("users").where("name", "=", "user1").get()
      var y = await rdb.table("users").where("name", "=", "user1' AND 'A' = 'B").get()
      echo x
      echo y
      check x != y
  test "3":
    asyncBlock:
      var x = await rdb.table("users").where("name", "=", "user1").get()
      var y = await rdb.table("users").where("name", "=", "user1' OR 'A' = 'B").get()
      echo x
      echo y
      check x != y
  test "4":
    asyncBlock:
      var x = await rdb.table("users").where("id", "=", 1).get()
      var y: seq[JsonNode]
      try:
        y = await rdb.table("users").where("id", "=", "2-1").get()
      except Exception:
        y = @[]
      echo x
      echo y
      check x != y
  test "5":
    asyncBlock:
      var x = await rdb.table("users").select("name", "email")
              .join("auth", "auth.id", "=", "users.auth_id")
              .where("auth.id", "=", 1).get()
      var y: seq[JsonNode]
      try:
        y = await rdb.table("users").select("name", "email")
                .join("auth", "auth.id", "=", "users.auth_id")
                .where("auth.id", "=", "2-1").get()
      except Exception:
        y = @[]
      echo x
      echo y
      check x != y
