import std/json
import std/strformat
import std/asyncdispatch
import std/oids
import std/times
import bcrypt
import ../../../../src/allographer/query_builder
import ../../connection
import ../../schema

proc userSeeder*() {.async.} =
  seeder(rdb, "user"):
    let salt = genSalt(10)
    
    var userList: seq[JsonNode]
    for i in 1..10:
      let row = UserTable(
        id: $genOid(),
        name: &"user {i}",
        email: &"user{i}@example.com",
        password: hash(&"password{i}", salt),
        createdAt: now().toTime().toUnix().int,
        updatedAt: now().toTime().toUnix().int,
      )
      userList.add(%row)

    rdb.table("user").insert(userList).await
