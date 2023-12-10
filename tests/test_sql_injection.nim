discard """
  cmd: "nim c -d:reset -r $file"
"""

import std/unittest
import std/json
import std/strformat
import std/asyncdispatch
import ../src/allographer/schema_builder
import ../src/allographer/query_builder
import ./connections


proc setUp(rdb:Rdb) =
  rdb.create(
    table("auth", [
      Column.increments("id"),
      Column.string("auth")
    ]),
    table("user",[
      Column.increments("id"),
      Column.string("name").nullable(),
      Column.string("email").nullable(),
      Column.string("password").nullable(),
      Column.string("salt").nullable(),
      Column.string("address").nullable(),
      Column.date("birth_date").nullable(),
      Column.foreign("auth_id").reference("id").onTable("auth").onDelete(SET_NULL)
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
          "email": &"user{i}@example.com",
          "auth_id": authId
        }
      )
    rdb.table("user").insert(insertData).await


for rdb in dbConnections:
  suite("sql injection"):
    setup:
      setUp(rdb)
    
    test("test1"):
      asyncBlock:
        var x = rdb.table("user").where("name", "=", "user1").get().await
        var y = rdb.table("user").where("name", "=", "user1' AND 'A' = 'A").get().await
        echo x
        echo y
        check x != y

    test("test2"):
      asyncBlock:
        var x = rdb.table("user").where("name", "=", "user1").get().await
        var y = rdb.table("user").where("name", "=", "user1' AND 'A' = 'B").get().await
        echo x
        echo y
        check x != y

    test("test3"):
      asyncBlock:
        var x = rdb.table("user").where("name", "=", "user1").get().await
        var y = rdb.table("user").where("name", "=", "user1' OR 'A' = 'B").get().await
        echo x
        echo y
        check x != y

    test("test4"):
      asyncBlock:
        var x = rdb.table("user").where("id", "=", 1).get().await
        var y: seq[JsonNode]
        try:
          y = rdb.table("user").where("id", "=", "2-1").get().await
        except Exception:
          y = @[]
        echo x
        echo y
        check x != y

    test("test5"):
      asyncBlock:
        var x = rdb.table("user").select("name", "email")
                .join("auth", "auth.id", "=", "user.auth_id")
                .where("auth.id", "=", 1)
                .get()
                .await
        var y: seq[JsonNode]
        try:
          y = rdb.table("user").select("name", "email")
                  .join("auth", "auth.id", "=", "user.auth_id")
                  .where("auth.id", "=", "2-1")
                  .get()
                  .await
        except Exception:
          y = @[]
        echo x
        echo y
        check x != y
