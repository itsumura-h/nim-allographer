import unittest, json, strformat, options, asyncdispatch

import ../src/allographer/query_builder
import ../src/allographer/schema_builder
import connections

rdb.schema(
  table("users", [
    Column().increments("id"),
    COlumn().string("name").nullable(),
    Column().date("birth_date").nullable(),
    Column().string("null").nullable(),
    Column().boolean("bool").default(false)
  ], reset=true)
)

var users: seq[JsonNode]
for i in 1..10:
  users.add(
    %*{
      "name": &"user{i}",
      "birth_date": &"1990-01-{i:02}"
    }
  )
asyncBlock:
  await rdb.table("users").insert(users)

suite "aggregates":
  test "count()":
    asyncBlock:
      var t = await rdb.table("users").count()
      echo t
      check t == 10

  test "max()":
    asyncBlock:
      var t = await(rdb.table("users").max("name")).get
      echo t
      check t == "user9"
      var t2 = await(rdb.table("users").max("id")).get
      echo t2
      check t2 == "10"

  test "min()":
    asyncBlock:
      var t = await(rdb.table("users").min("name")).get
      echo t
      check t == "user1"
      var t2 = await(rdb.table("users").min("id")).get
      echo t2
      check t2 == "1"

  test "avg()":
    asyncBlock:
      var t = await(rdb.table("users").avg("id")).get
      echo t
      check t == 5.5

  test "sum()":
    asyncBlock:
      var t = await(rdb.table("users").sum("id")).get
      echo t
      check t == 55.0
