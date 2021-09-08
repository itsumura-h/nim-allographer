discard """
  cmd: "nim c -d:reset -r $file"
"""

import unittest, strformat, json, strutils, options, asyncdispatch
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
for i in 1..5:
  users.add(
    %*{
      "name": &"user{i}",
      "birth_date": &"1990-01-0{i}"
    }
  )
asyncBlock:
  await rdb.table("users").insert(users)


type Typ = ref object
  id:int
  name:string
  birth_date:string
  null:string
  bool:bool

proc checkTest(t:Typ, r:Typ) =
  check t.id == r.id
  check t.name == r.name
  check t.birth_date == r.birth_date
  check t.null == r.null
  check t.bool == r.bool

proc checkTestOptions(t:Typ, r:Option[Typ]) =
  check t.id == r.get.id
  check t.name == r.get.name
  check t.birth_date == r.get.birth_date
  check t.null == r.get.null
  check t.bool == r.get.bool

block:
  asyncBlock:
    var t = Typ(id:1, name:"user1", birth_date:"1990-01-01", null:"")
    var r = await(rdb.table("users").get()).orm(Typ)[0]
    checkTest(t, r)
block:
  asyncBlock:
    var t = Typ(id:1, name:"user1", birth_date:"1990-01-01", null:"")
    var r = await(rdb.raw("select * from users").getRaw()).orm(Typ)[0]
    checkTest(t, r)
block:
  asyncBlock:
    var t = Typ(id:1, name:"user1", birth_date:"1990-01-01", null:"")
    var r = await(rdb.table("users").first()).orm(Typ)
    checkTestOptions(t, r)
block:
  asyncBlock:
    var t = Typ(id:1, name:"user1", birth_date:"1990-01-01", null:"")
    var r = await(rdb.table("users").find(1)).orm(Typ)
    checkTestOptions(t, r)
block:
  asyncBlock:
    transaction rdb:
      var t = Typ(id:1, name:"user1", birth_date:"1990-01-01", null:"")
      var rArr = @[
        await(rdb.table("users").get())[0].orm(Typ),
        await(rdb.raw("select * from users").getRaw())[0].orm(Typ),
      ]
      for r in rArr:
        checkTest(t, r)
      var rArr2 = @[
        await(rdb.table("users").first()).orm(Typ),
        await(rdb.table("users").find(1)).orm(Typ)
      ]
      for r in rArr2:
        checkTestOptions(t, r)

block:
  asyncBlock:
    var r = await(rdb.table("users").where("id", ">", 10).get()).orm(Typ)
    check r.len == 0
    check r == newSeq[Typ](0)
block:
  asyncBlock:
    var r = await(rdb.raw("select * from users where id > ?", "10").getRaw()).orm(Typ)
    check r.len == 0
    check r == newSeq[Typ](0)
block:
  asyncBlock:
    var r = await(rdb.table("users").where("id", ">", 10).first()).orm(Typ)
    check r.isSome() == false
block:
  asyncBlock:
    var r = await(rdb.table("users").find(10)).orm(Typ)
    check r.isSome() == false

rdb.alter(
  drop("users")
)
