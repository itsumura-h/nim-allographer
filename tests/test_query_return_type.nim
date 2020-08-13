import unittest, strformat, json, strutils, options

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
for i in 1..5:
  users.add(
    %*{
      "name": &"user{i}",
      "birth_date": &"1990-01-0{i}"
    }
  )

rdb().table("users").insert(users)


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
  check t.id == r.get().id
  check t.name == r.get().name
  check t.birth_date == r.get().birth_date
  check t.null == r.get().null
  check t.bool == r.get().bool

suite "return with type":
  test "get":
    var t = Typ(id:1, name:"user1", birth_date:"1990-01-01", null:"")
    var r = rdb().table("users").get(Typ)[0]
    checkTest(t, r)
  test "getRaw":
    var t = Typ(id:1, name:"user1", birth_date:"1990-01-01", null:"")
    var r = rdb().raw("select * from users").getRaw(Typ)[0]
    checkTest(t, r)
  test "first":
    var t = Typ(id:1, name:"user1", birth_date:"1990-01-01", null:"")
    var r = rdb().table("users").first(Typ)
    checkTestOptions(t, r)
  test "find":
    var t = Typ(id:1, name:"user1", birth_date:"1990-01-01", null:"")
    var r = rdb().table("users").find(1, Typ)
    checkTestOptions(t, r)
  test "transaction":
    transaction:
      var t = Typ(id:1, name:"user1", birth_date:"1990-01-01", null:"")
      var rArr = @[
        rdb().table("users").get(Typ)[0],
        rdb().raw("select * from users").getRaw(Typ)[0],
      ]
      for r in rArr:
        checkTest(t, r)
      var rArr2 = @[
        rdb().table("users").first(Typ),
        rdb().table("users").find(1, Typ)
      ]
      for r in rArr2:
        checkTestOptions(t, r)

suite "return with type fail":
  test "get":
    var r = rdb().table("users").where("id", ">", 10).get(Typ)
    check r.len == 0
    check r == newSeq[Typ](0)
  test "getRaw":
    var r = rdb().raw("select * from users where id > 10").getRaw(Typ)
    check r.len == 0
    check r == newSeq[Typ](0)
  test "first":
    var r = rdb().table("users").where("id", ">", 10).first(Typ)
    check r.isSome() == false
  test "find":
    var r = rdb().table("users").find(10, Typ)
    check r.isSome() == false

alter(
  drop("users")
)
