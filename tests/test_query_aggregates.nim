discard """
  cmd: "nim c -d:reset -r $file"
"""

import unittest, json, strformat, options, asyncdispatch

import ../src/allographer/query_builder
import ../src/allographer/schema_builder
import connections

rdb.create(
  table("users", [
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
  await rdb.table("users").insert(users)

block countTest:
  asyncBlock:
    var t = await rdb.table("users").count()
    echo t
    check t == 10

block maxTest:
  asyncBlock:
    var t = await(rdb.table("users").max("name")).get
    echo t
    check t == "user9"
    var t2 = await(rdb.table("users").max("id")).get
    echo t2
    check t2 == "10"

block minTest:
  asyncBlock:
    var t = await(rdb.table("users").min("name")).get
    echo t
    check t == "user1"
    var t2 = await(rdb.table("users").min("id")).get
    echo t2
    check t2 == "1"

block avgTest:
  asyncBlock:
    var t = await(rdb.table("users").avg("id")).get
    echo t
    check t == 5.5

block sumTest:
  asyncBlock:
    var t = await(rdb.table("users").sum("id")).get
    echo t
    check t == 55.0
