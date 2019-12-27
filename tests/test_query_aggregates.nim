import unittest, json, strformat

import ../src/allographer/query_builder
import ../src/allographer/schema_builder

Schema().create(
  Table().create("users", [
    Column().increments("id"),
    COlumn().string("name").nullable(),
    Column().date("birth_date").nullable(),
    Column().string("null").nullable(),
    Column().boolean("bool").default(false)
  ], reset=true)
)

var users: seq[JsonNode]
for i in 1..5:
  users.add(
    %*{
      "name": &"user{i}",
      "birth_date": &"1990-01-0{i}"
    }
  )

RDB().table("users").insert(users)

suite "aggregates":
  test "count()":
    var t = RDB().table("users").count()
    echo t
    check t == 5

  test "max()":
    var t = RDB().table("users").max("name")
    echo t
    check t == "user5"