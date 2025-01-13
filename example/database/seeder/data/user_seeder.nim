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
  let userCount = rdb.table("user").count().await
  if userCount > 0:
    return

  let salt = genSalt(10)

  var data: seq[JsonNode] = @[]
  for i in 0..10:
    let user = UserTable(
      id: $genOid(),
      name: &"user {i}",
      email: &"user{i}@example.com",
      password: hash(&"password{i}", salt),
      createdAt: now().format("yyyy-MM-dd HH:mm:ss"),
      updatedAt: now().format("yyyy-MM-dd HH:mm:ss"),
    )
    data.add(%user)
  
  rdb.table("user").insert(data).await


userSeeder().waitFor
