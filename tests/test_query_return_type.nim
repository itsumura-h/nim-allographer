discard """
  cmd: "nim c -d:reset -r $file"
"""

import std/unittest
import strformat
import std/json
import std/strutils
import std/options
import std/asyncdispatch
import ../src/allographer/query_builder
import ../src/allographer/schema_builder
import ./connections
import ../src/allographer/query_builder/rdb/rdb_utils
# import ../src/allographer/utils


proc setUp(rdb:Rdb) =
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
  for i in 1..5:
    users.add(
      %*{
        "name": &"user{i}",
        "birth_date": &"1990-01-0{i}"
      }
    )
  asyncBlock:
    await rdb.table("user").insert(users)


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

for rdb in dbConnections:
  suite("query return type"):
    setup:
      setUp(rdb)

    test("test1"):
      asyncBlock:
        var t = Typ(id:1, name:"user1", birth_date:"1990-01-01", null:"")
        var r = await(rdb.table("user").get(Typ))[0]
        checkTest(t, r)
    
    test("test2"):
      asyncBlock:
        var t = Typ(id:1, name:"user1", birth_date:"1990-01-01", null:"")
        var table = "user"
        quote(table, rdb.driver)
        var r = rdb.raw(&"SELECT * FROM {table}").get(Typ).await()[0]
        checkTest(t, r)

    test("test3"):
      asyncBlock:
        var t = Typ(id:1, name:"user1", birth_date:"1990-01-01", null:"")
        var r = await rdb.table("user").first(Typ)
        checkTestOptions(t, r)

    test("test4"):
      asyncBlock:
        var t = Typ(id:1, name:"user1", birth_date:"1990-01-01", null:"")
        var r = await(rdb.table("user").find(1, Typ))
        checkTestOptions(t, r)
    
    test("test5"):
      asyncBlock:
        transaction rdb:
          var t = Typ(id:1, name:"user1", birth_date:"1990-01-01", null:"")
          var table = "user"
          quote(table, rdb.driver)
          var rArr = @[
            await(rdb.table("user").get(Typ))[0],
            await(rdb.raw(&"SELECT * FROM {table}").get(Typ))[0],
          ]
          for r in rArr:
            checkTest(t, r)
          var rArr2 = @[
            await(rdb.table("user").first(Typ)),
            await(rdb.table("user").find(1, Typ))
          ]
          for r in rArr2:
            checkTestOptions(t, r)

    test("test6"):
      asyncBlock:
        var r = await(rdb.table("user").where("id", ">", 10).get(Typ))
        check r.len == 0
        check r == newSeq[Typ](0)
    
    test("test6"):
      asyncBlock:
        var r = await(rdb.raw("SELECT * FROM user WHERE id > ?", "10").get(Typ))
        check r.len == 0
        check r == newSeq[Typ](0)
    test("test7"):
      asyncBlock:
        var r = await(rdb.table("user").where("id", ">", 10).first(Typ))
        check r.isSome() == false
    
    test("test8"):
      asyncBlock:
        var r = await(rdb.table("user").find(10, Typ))
        check r.isSome() == false

  rdb.drop(
    table("user")
  )
