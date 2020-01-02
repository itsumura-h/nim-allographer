import unittest, json, strformat

import ../src/allographer/schema_builder
import ../src/allographer/query_builder
from ../src/allographer/connection import getDriver


Schema().create([
  Table().create("auth",[
    Column().increments("id"),
    Column().string("auth")
  ], reset=true),
  Table().create("users",[
    Column().increments("id"),
    Column().string("name").nullable(),
    Column().string("email").nullable(),
    Column().string("address").nullable(),
    Column().foreign("auth_id").reference("id").on("auth").onDelete(SET_NULL)
  ], reset=true)
])

# seeder
RDB().table("auth").insert([
  %*{"auth": "admin"},
  %*{"auth": "user"}
])

var insertData: seq[JsonNode]
for i in 1..20:
  let authId = if i mod 2 == 0: 2 else: 1
  insertData.add(
    %*{
      "name": &"user{i}",
      "email": &"user{i}@gmail.com",
      "auth_id": authId
    }
  )

RDB().table("users").insert(insertData)
RDB().table("users").delete(2)
RDB().table("users").delete(6)

suite "query pagination":
  test "count":
    var t = RDB().table("users").select("id", "name").paginate(3, 2)
    echo t
    check t["count"].getInt() == 3
    
  test "currentPage":
    var t = RDB().table("users").select("id", "name").paginate(3, 2)
    check t["currentPage"][0]["id"].getInt() == 5

  test "hasMorePages":
    var t = RDB().table("users").select("id", "name").paginate(3, 2)
    check t["hasMorePages"].getBool() == true

  test "lastPage":
    var t = RDB().table("users").select("id", "name").paginate(3, 2)
    check t["lastPage"].getInt() == 6

  test "nextPage":
    var t = RDB().table("users").select("id", "name").paginate(3, 3)
    check t["nextPage"].getInt() == 4

  test "perPage":
    var t = RDB().table("users").select("id", "name").paginate(3, 2)
    check t["perPage"].getInt() == 3

  test "previousPage":
    var t = RDB().table("users").select("id", "name").paginate(3, 1)
    check t["previousPage"].getInt() == 1

  test "total":
    var t = RDB().table("users").select("id", "name").paginate(3, 2)
    check t["total"].getInt() == 18
  
  test "fastPaginate":
    var t = RDB().table("users").select("id", "name").fastPaginate(4)
    echo t
    t = RDB().table("users").select("id", "name").fastPaginateNext(4, t["nextPage"].getInt())
    echo t
    t = RDB().table("users").select("id", "name").fastPaginateNext(4, t["nextPage"].getInt())
    echo t

    t = RDB().table("users").select("id", "name").fastPaginateBack(4, t["previousPage"].getInt())
    echo t
    t = RDB().table("users").select("id", "name").fastPaginateBack(4, t["previousPage"].getInt())
    echo t