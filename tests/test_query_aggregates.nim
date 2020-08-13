import unittest, json, strformat

import ../src/allographer/query_builder
import ../src/allographer/schema_builder

schema(
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

rdb().table("users").insert(users)

suite "aggregates":
  test "count()":
    var t = rdb().table("users").count()
    echo t
    check t == 10

  test "max()":
    var t = rdb().table("users").max("name")
    echo t
    check t == "user9"
    var t2 = rdb().table("users").max("id")
    echo t2
    check t2 == "10"

  test "min()":
    var t = rdb().table("users").min("name")
    echo t
    check t == "user1"
    var t2 = rdb().table("users").min("id")
    echo t2
    check t2 == "1"

  test "avg()":
    var t = rdb().table("users").avg("id")
    echo t
    check t == 5.5

  test "sum()":
    var t = rdb().table("users").sum("id")
    echo t
    check t == 55.0