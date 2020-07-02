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

RDB().table("users").insert(users)


type Typ = ref object
  id:int
  name:string
  birth_date:string
  null:string
  bool:bool

suite "return with type":
  test "get":
    var t = Typ(id:1, name:"user1", birth_date:"1990-01-01", null:"")
    var r = RDB().table("users").get(Typ)[0]
    check t.id == r.id
    check t.name == r.name
    check t.birth_date == r.birth_date
    check t.null == r.null
    check t.bool == r.bool
  test "getRaw":
    var t = Typ(id:1, name:"user1", birth_date:"1990-01-01", null:"")
    var r = RDB().raw("select * from users").getRaw(Typ)[0]
    check t.id == r.id
    check t.name == r.name
    check t.birth_date == r.birth_date
    check t.null == r.null
    check t.bool == r.bool
  test "first":
    var t = Typ(id:1, name:"user1", birth_date:"1990-01-01", null:"")
    var r = RDB().table("users").first(Typ)
    if r.isSome():
      check t.id == r.get().id
      check t.name == r.get().name
      check t.birth_date == r.get().birth_date
      check t.null == r.get().null
      check t.bool == r.get().bool
    else:
      check false
  test "find":
    var t = Typ(id:1, name:"user1", birth_date:"1990-01-01", null:"")
    var r = RDB().table("users").find(1, Typ)
    if r.isSome():
      check t.id == r.get().id
      check t.name == r.get().name
      check t.birth_date == r.get().birth_date
      check t.null == r.get().null
      check t.bool == r.get().bool
    else:
      check false

suite "return with type fail":
  test "get":
    var t = Typ(id:1, name:"user1", birth_date:"1990-01-01", null:"")
    var r = RDB().table("users").where("id", ">", 10).get(Typ)
    check r == newSeq[Typ](0)
  test "getRaw":
    var t = Typ(id:1, name:"user1", birth_date:"1990-01-01", null:"")
    var r = RDB().raw("select * from users where id > 10").getRaw(Typ)
    check r == newSeq[Typ](0)
  test "first":
    var t = Typ(id:1, name:"user1", birth_date:"1990-01-01", null:"")
    var r = RDB().table("users").where("id", ">", 10).first(Typ)
    if not r.isSome():
      check r.isNone()
    else:
      check false
  test "find":
    var t = Typ(id:1, name:"user1", birth_date:"1990-01-01", null:"")
    var r = RDB().table("users").find(10, Typ)
    if not r.isSome():
      check r.isNone()
    else:
      check false

RDB().raw("DROP TABLE users").exec()
