discard """
  cmd: "nim c --mm:orc -d:reset -r $file"
"""

import std/unittest
import std/json
import std/strformat
import std/strutils
import std/options
import std/asyncdispatch
import ../src/allographer/schema_builder
import ../src/allographer/query_builder
import ./connections


proc setUp(rdb:Rdb) =
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

  seeder rdb, "user":
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

    rdb.table("user").insert(users).waitFor


for rdb in dbConnectionsTransacion:
  suite("transaction"):
    setup:
      setUp(rdb)
    
    test("get"):
      asyncBlock:
        var user = rdb.table("user").get().await
        echo user
        check true

    test("find"):
      asyncBlock:
        transaction rdb:
          var user = rdb.table("user").select("id").where("name", "=", "user3").first.await.get
          var id = user["id"].getInt()
          user = rdb.table("user").select("name", "email").find(id).await.get
          check user == %*{"name":"user3","email":"user3@example.com"}

    test("insert"):
      asyncBlock:
        transaction rdb:
          rdb.table("table").insert(%*{"aaa": "bbb"}).await
          check false
        check true

    test("insertId"):
      setup(rdb)
      asyncBlock:
        var id:int
        transaction rdb:
          id = rdb.table("user")
                    .insertId(%*{"name": "user11", "email": "user11@example.com"})
                    .await
          echo id
        check rdb.table("user").max("id").await.get == $id
