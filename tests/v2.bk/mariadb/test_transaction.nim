discard """
  cmd: "nim c --mm:orc -d:reset -r $file"
"""

import std/unittest
import std/json
import std/strformat
import std/strutils
import std/options
import std/asyncdispatch
import ../../../src/allographer/schema_builder
import ../../../src/allographer/query_builder
import ../../connections
import ../../clear_tables


let rdb = mariadb

proc setUp(rdb:MariadbConnections) =
  rdb.create([
    table("auth",[
      Column.increments("id"),
      Column.string("auth")
    ]),
    table("user",[
      Column.increments("id"),
      Column.string("name").nullable(),
      Column.string("email").nullable(),
      Column.string("address").nullable(),
      Column.foreign("auth_id").reference("id").onTable("auth").onDelete(SET_NULL)
    ])
  ])

  # seeder
  seeder(rdb, "auth"):
    rdb.table("auth").insert(@[
      %*{"auth": "admin"},
      %*{"auth": "user"}
    ])
    .waitFor()

  seeder(rdb, "user"):
    var users: seq[JsonNode]
    for i in 1..10:
      let authId = if i mod 2 == 0: 2 else: 1
      users.add(
        %*{
          "name": &"user{i}",
          "email": &"user{i}@example.com",
          "auth_id": authId
        }
      )

    rdb.table("user").insert(users).waitFor()


suite("raw code transaction"):
  setup:
    setUp(rdb)
  
  test("commit"):
    (proc() {.async.} =
      var user1 = rdb.table("user").find(1).await.get()
      check user1["name"].getStr() == "user1"

      block:
        rdb.begin().await
        try:
          rdb.table("user").where("id", "=", 1).update(%*{"name": "updated"}).await
          rdb.commit().await
        except CatchableError:
          rdb.rollback().await

      user1 = rdb.table("user").find(1).await.get()
      check user1["name"].getStr() == "updated"
    )().waitFor


  test("rollback"):
    (proc() {.async.} =
      var user1 = rdb.table("user").find(1).await.get()
      check user1["name"].getStr() == "user1"
      
      block:
        rdb.begin().await
        try:
          rdb.table("user").where("id", "=", 1).update(%*{"name": "updated"}).await
          raise newException(CatchableError, "")
        except:
          rdb.rollback().await

      user1 = rdb.table("user").find(1).await.get()
      check user1["name"].getStr() == "user1"
    )().waitFor


suite("transaction template"):
  setup:
    setUp(rdb)

  test("commit"):
    (proc(){.async.} =
      var user1 = rdb.table("user").find(1).await.get()
      check user1["name"].getStr() == "user1"

      transaction(rdb):
        rdb.table("user").where("id", "=", 1).update(%*{"name": "updated"}).await

      user1 = rdb.table("user").find(1).await.get()
      check user1["name"].getStr() == "updated"
    )().waitFor()


  test("rollback"):
    (proc(){.async.} =
      var user1 = rdb.table("user").find(1).await.get()
      check user1["name"].getStr() == "user1"

      transaction(rdb):
        rdb.table("user").where("id", "=", 1).update(%*{"name": "updated"}).await
        raise newException(DbError, "")

      user1 = rdb.table("user").find(1).await.get()
      check user1["name"].getStr() == "user1"
    )().waitFor()


clearTables(rdb).waitFor()
