discard """
  cmd: "nim c -d:reset -r $file"
"""

import std/unittest
import std/json
import std/strformat
import std/options
import std/asyncdispatch
import ../src/allographer/query_builder
import ../src/allographer/schema_builder
import ./connections


for rdb in dbConnections:
  rdb.create(
    table("user", [
      Column.increments("id"),
      Column.string("name").nullable(),
      Column.date("birth_date").nullable(),
      Column.string("null").nullable(),
      Column.boolean("bool").default(false)
    ])
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
    await rdb.table("user").insert(users)

  suite "query aggregates":
    test "count":
      asyncBlock:
        var t = await rdb.table("user").count()
        echo t
        check t == 10

    test "maxTest":
      asyncBlock:
        var t = await(rdb.table("user").max("name")).get
        echo t
        check t == "user9"
        var t2 = await(rdb.table("user").max("id")).get
        echo t2
        check t2 == "10"

    test "minTest":
      asyncBlock:
        var t = await(rdb.table("user").min("name")).get
        echo t
        check t == "user1"
        var t2 = await(rdb.table("user").min("id")).get
        echo t2
        check t2 == "1"

    test "avgTest":
      asyncBlock:
        var t = await(rdb.table("user").avg("id")).get
        echo t
        check t == 5.5

    test "sumTest":
      asyncBlock:
        var t = await(rdb.table("user").sum("id")).get
        echo t
        check t == 55.0
