discard """
  cmd: "nim c -d:reset -r $file"
"""

import
  std/unittest,
  std/json,
  std/strformat,
  std/asyncdispatch,
  ../src/allographer/schema_builder,
  ../src/allographer/query_builder,
  ./connections


proc setup(rdb:Rdb) =
  rdb.create(
    table("auth", [
      Column.increments("id"),
      Column.string("auth")
    ]),
    table("users",[
      Column.increments("id"),
      Column.string("name").nullable(),
      Column.string("email").nullable(),
      Column.string("password").nullable(),
      Column.string("salt").nullable(),
      Column.string("address").nullable(),
      Column.date("birth_date").nullable(),
      Column.foreign("auth_id").reference("id").on("auth").onDelete(SET_NULL)
    ])
  )

  # シーダー
  asyncBlock:
    rdb.table("auth").insert(@[
      %*{"auth": "admin"},
      %*{"auth": "user"}
    ])
    .await
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
    rdb.table("users").insert(insertData).await


for rdb in dbConnections:
  block:
    setup(rdb)
    asyncBlock:
      var x = rdb.table("users").where("name", "=", "user1").get().await
      var y = rdb.table("users").where("name", "=", "user1' AND 'A' = 'A").get().await
      echo x
      echo y
      check x != y

  block:
    setup(rdb)
    asyncBlock:
      var x = rdb.table("users").where("name", "=", "user1").get().await
      var y = rdb.table("users").where("name", "=", "user1' AND 'A' = 'B").get().await
      echo x
      echo y
      check x != y

  block:
    setup(rdb)
    asyncBlock:
      var x = rdb.table("users").where("name", "=", "user1").get().await
      var y = rdb.table("users").where("name", "=", "user1' OR 'A' = 'B").get().await
      echo x
      echo y
      check x != y

  block:
    setup(rdb)
    asyncBlock:
      var x = rdb.table("users").where("id", "=", 1).get().await
      var y: seq[JsonNode]
      try:
        y = rdb.table("users").where("id", "=", "2-1").get().await
      except Exception:
        y = @[]
      echo x
      echo y
      check x != y

  block:
    setup(rdb)
    asyncBlock:
      var x = rdb.table("users").select("name", "email")
              .join("auth", "auth.id", "=", "users.auth_id")
              .where("auth.id", "=", 1)
              .get()
              .await
      var y: seq[JsonNode]
      try:
        y = rdb.table("users").select("name", "email")
                .join("auth", "auth.id", "=", "users.auth_id")
                .where("auth.id", "=", "2-1")
                .get()
                .await
      except Exception:
        y = @[]
      echo x
      echo y
      check x != y
