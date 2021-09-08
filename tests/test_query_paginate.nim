discard """
  cmd: "nim c -d:reset -r $file"
"""

import unittest, json, strformat, asyncdispatch
import ../src/allographer/schema_builder
import ../src/allographer/query_builder
import connections

rdb.schema([
  table("auth",[
    Column().increments("id"),
    Column().string("auth")
  ]),
  table("users",[
    Column().increments("id"),
    Column().string("name").nullable(),
    Column().string("email").nullable(),
    Column().string("address").nullable(),
    Column().foreign("auth_id").reference("id").on("auth").onDelete(SET_NULL)
  ])
])

# seeder
asyncBlock:
  await rdb.table("auth").insert(@[
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

asyncBlock:
  await rdb.table("users").insert(insertData)


block:
  asyncBlock:
    var t = await rdb.table("users").select("id", "name").paginate(3, 2)
    echo t
    check t["count"].getInt() == 3

block:
  asyncBlock:
    var t = await rdb.table("users").select("id", "name").paginate(3, 2)
    check t["currentPage"][0]["id"].getInt() == 4

block:
  asyncBlock:
    var t = await rdb.table("users").select("id", "name").paginate(3, 2)
    check t["hasMorePages"].getBool() == true

block:
  asyncBlock:
    var t = await rdb.table("users").select("id", "name").paginate(3, 2)
    check t["lastPage"].getInt() == 6

block:
  asyncBlock:
    var t = await rdb.table("users").select("id", "name").paginate(3, 3)
    check t["nextPage"].getInt() == 4

block:
  asyncBlock:
    var t = await rdb.table("users").select("id", "name").paginate(3, 2)
    check t["perPage"].getInt() == 3

block:
  asyncBlock:
    var t = await rdb.table("users").select("id", "name").paginate(3, 1)
    check t["previousPage"].getInt() == 1

block:
  asyncBlock:
    var t = await rdb.table("users").select("id", "name").paginate(3, 2)
    check t["total"].getInt() == 20

block:
  asyncBlock:
    var t = await rdb.table("users").select("id", "name").fastPaginate(3)
    echo t
    check t["previousId"].getInt == 0
    check t["currentPage"][0]["id"].getInt == 1
    check t["nextId"].getInt == 4

block:
  asyncBlock:
    var t = await rdb.table("users").select("id", "name").fastPaginate(3, order=Desc)
    echo t
    check t["previousId"].getInt == 0
    check t["currentPage"][0]["id"].getInt == 20
    check t["nextId"].getInt == 17

block:
  asyncBlock:
    var t = await rdb.table("users").select("id", "name").fastPaginateNext(3, 5)
    echo t
    check t["previousId"].getInt == 4
    check t["currentPage"][0]["id"].getInt == 5
    check t["nextId"].getInt == 8

block:
  asyncBlock:
    var t = await rdb.table("users").select("id", "name").fastPaginateNext(3, 5, order=Desc)
    echo t
    check t["previousId"].getInt == 6
    check t["currentPage"][0]["id"].getInt == 5
    check t["nextId"].getInt == 2

block:
  asyncBlock:
    var t = await rdb.table("users").select("id", "name").fastPaginateBack(3, 5)
    echo t
    check t["previousId"].getInt == 2
    check t["currentPage"][0]["id"].getInt == 3
    check t["nextId"].getInt == 6

block:
  asyncBlock:
    var t = await rdb.table("users").select("id", "name").fastPaginateBack(3, 5, order=Desc)
    echo t
    check t["previousId"].getInt == 8
    check t["currentPage"][0]["id"].getInt == 7
    check t["nextId"].getInt == 4

block:
  asyncBlock:
    var t = await rdb.table("users")
            .select("users.id", "users.name", "users.auth_id")
            .join("auth", "auth.id", "=", "users.auth_id")
            .where("auth.id", "=", 2)
            .fastPaginate(3, key="users.id")
    echo t
    check t["hasPreviousId"].getBool == false
    check t["currentPage"][0]["id"].getInt == 2
    check t["nextId"].getInt == 8

block:
  asyncBlock:
    var t = await rdb.table("users")
            .select("users.id", "users.name")
            .join("auth", "auth.id", "=", "users.auth_id")
            .where("auth.id", "=", 2)
            .fastPaginate(3, key="users.id")

    t = await rdb.table("users")
            .select("users.id", "users.name")
            .join("auth", "auth.id", "=", "users.auth_id")
            .where("auth.id", "=", 2)
            .fastPaginateNext(3, t["nextId"].getInt, key="users.id")
    echo t
    check t["previousId"].getInt == 6
    check t["currentPage"][0]["id"].getInt == 8
    check t["nextId"].getInt == 14

block:
  asyncBlock:
    var t = await rdb.table("users")
            .select("users.id", "users.name")
            .join("auth", "auth.id", "=", "users.auth_id")
            .where("auth.id", "=", 2)
            .fastPaginateNext(3, 10, key="users.id")

    t = await rdb.table("users")
            .select("users.id", "users.name")
            .join("auth", "auth.id", "=", "users.auth_id")
            .where("auth.id", "=", 2)
            .fastPaginateBack(3, t["previousId"].getInt, key="users.id")
    echo t
    check t["hasPreviousId"].getBool == true
    check t["currentPage"][0]["id"].getInt == 4
    check t["nextId"].getInt == 10

block:
  asyncBlock:
    var t = await rdb.table("users")
            .select("users.id", "users.name")
            .where("id", "<", "2")
            .fastPaginate(2, key="users.id")
    echo t
    check t["currentPage"].len == 1
    check t["hasNextId"].getBool == false

block:
  asyncBlock:
    var t = await rdb.table("users")
            .select("users.id", "users.name")
            .where("id", "<", "4")
            .fastPaginate(2, key="users.id")
    echo t
    check t["currentPage"].len == 2
    check t["hasNextId"].getBool == true

block:
  asyncBlock:
    var t = await rdb.table("users")
            .select("users.id", "users.name")
            .where("id", "<", "5")
            .fastPaginate(2, key="users.id")
    echo t
    check t["currentPage"].len == 2
    check t["hasNextId"].getBool == true

block:
  asyncBlock:
    var t = await rdb.table("users")
            .select("users.id", "users.name")
            .where("id", "<", "2")
            .fastPaginateNext(2, 1, key="users.id")
    echo t
    check t["currentPage"].len == 1
    check t["hasNextId"].getBool == false

block:
  asyncBlock:
    var t = await rdb.table("users")
            .select("users.id", "users.name")
            .where("id", "<", "4")
            .fastPaginateNext(2, 1, key="users.id")
    echo t
    check t["currentPage"].len == 2
    check t["hasNextId"].getBool == true

block:
  asyncBlock:
    var t = await rdb.table("users")
            .select("users.id", "users.name")
            .where("id", "<", "5")
            .fastPaginateNext(2, 1, key="users.id")
    echo t
    check t["currentPage"].len == 2
    check t["hasNextId"].getBool == true


block:
  asyncBlock:
    var t = await rdb.table("users")
            .select("users.id", "users.name")
            .where("id", ">=", 20)
            .fastPaginateBack(2, 20, key="users.id")
    echo t
    check t["currentPage"].len == 1
    check t["hasPreviousId"].getBool == false

block:
  asyncBlock:
    var t = await rdb.table("users")
            .select("users.id", "users.name")
            .where("id", ">=", 19)
            .fastPaginateBack(2, 20, key="users.id")
    echo t
    check t["currentPage"].len == 2
    check t["hasPreviousId"].getBool == false

block:
  asyncBlock:
    var t = await rdb.table("users")
            .select("users.id", "users.name")
            .where("id", ">=", 18)
            .fastPaginateBack(2, 20, key="users.id")
    echo t
    check t["currentPage"].len == 2
    check t["hasPreviousId"].getBool == true
