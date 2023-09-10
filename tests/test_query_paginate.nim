discard """
  cmd: "nim c -d:reset -r $file"
"""

import std/unittest
import std/json
import std/strformat
import std/asyncdispatch
import ../src/allographer/schema_builder
import ../src/allographer/query_builder
import ./connections


for rdb in dbConnections:
  rdb.create([
    table("auth",[
      Column.increments("id"),
      Column.string("auth")
    ]),
    table("user",[
      Column.increments("id"),
      Column.string("name").nullable(),
      Column.string("email").nullable(),
      Column.string("address").nullable(),
      Column.foreign("auth_id").reference("id").on("auth").onDelete(SET_NULL)
    ])
  ])

  # seeder
  seeder rdb, "auth":
    rdb.table("auth").insert(@[
      %*{"auth": "admin"},
      %*{"auth": "user"}
    ])
    .waitFor

  seeder rdb, "user":
    var insertData: seq[JsonNode]
    for i in 1..20:
      let authId = if i mod 2 == 0: 2 else: 1
      insertData.add(
        %*{
          "name": &"user{i}",
          "email": &"user{i}@example.com",
          "auth_id": authId
        }
      )

    rdb.table("user").insert(insertData).waitFor


  suite "query pagination":
    test "test 1":
      asyncBlock:
        var t = rdb.table("user").select("id", "name").paginate(3, 2).await
        echo t
        check t["count"].getInt() == 3

    test "test 2":
      asyncBlock:
        var t = rdb.table("user").select("id", "name").paginate(3, 2).await
        check t["currentPage"][0]["id"].getInt() == 4

    test "test 3":
      asyncBlock:
        var t = rdb.table("user").select("id", "name").paginate(3, 2).await
        check t["hasMorePages"].getBool() == true

    test "test 4":
      asyncBlock:
        var t = rdb.table("user").select("id", "name").paginate(3, 2).await
        check t["lastPage"].getInt() == 6

    test "test 5":
      asyncBlock:
        var t = rdb.table("user").select("id", "name").paginate(3, 3).await
        check t["nextPage"].getInt() == 4

    test "test 6":
      asyncBlock:
        var t = rdb.table("user").select("id", "name").paginate(3, 2).await
        check t["perPage"].getInt() == 3

    test "test 7":
      asyncBlock:
        var t = rdb.table("user").select("id", "name").paginate(3, 1).await
        check t["previousPage"].getInt() == 1

    test "test 8":
      asyncBlock:
        var t = rdb.table("user").select("id", "name").paginate(3, 2).await
        check t["total"].getInt() == 20

    test "test 9":
      asyncBlock:
        var t = rdb.table("user").select("id", "name").fastPaginate(3).await
        echo t
        check t["previousId"].getInt == 0
        check t["currentPage"][0]["id"].getInt == 1
        check t["nextId"].getInt == 4

    test "test 10":
      asyncBlock:
        var t = rdb.table("user").select("id", "name").fastPaginate(3, order=Desc).await
        echo t
        check t["previousId"].getInt == 0
        check t["currentPage"][0]["id"].getInt == 20
        check t["nextId"].getInt == 17

    test "test 11":
      asyncBlock:
        var t = rdb.table("user").select("id", "name").fastPaginateNext(3, 5).await
        echo t
        check t["previousId"].getInt == 4
        check t["currentPage"][0]["id"].getInt == 5
        check t["nextId"].getInt == 8

    test "test 12":
      asyncBlock:
        var t = rdb.table("user").select("id", "name").fastPaginateNext(3, 5, order=Desc).await
        echo t
        check t["previousId"].getInt == 6
        check t["currentPage"][0]["id"].getInt == 5
        check t["nextId"].getInt == 2

    test "test 13":
      asyncBlock:
        var t = rdb.table("user").select("id", "name").fastPaginateBack(3, 5).await
        echo t
        check t["previousId"].getInt == 2
        check t["currentPage"][0]["id"].getInt == 3
        check t["nextId"].getInt == 6

    test "test 14":
      asyncBlock:
        var t = rdb.table("user").select("id", "name").fastPaginateBack(3, 5, order=Desc).await
        echo t
        check t["previousId"].getInt == 8
        check t["currentPage"][0]["id"].getInt == 7
        check t["nextId"].getInt == 4

    test "test 15":
      asyncBlock:
        var t = rdb.table("user")
                .select("user.id as user_id", "user.name as user_name", "user.auth_id as auth_id")
                .join("auth", "auth.id", "=", "auth_id")
                .where("auth.id", "=", 2)
                .fastPaginate(3, key="user_id")
                .await
        echo t
        check t["hasPreviousId"].getBool == false
        check t["currentPage"][0]["user_id"].getInt == 2
        check t["nextId"].getInt == 8

    test "test 16":
      asyncBlock:
        var t = rdb.table("user")
                .select("user.id", "user.name")
                .join("auth", "auth.id", "=", "user.auth_id")
                .where("auth.id", "=", 2)
                .fastPaginate(3, key="user.id")
                .await

        t = rdb.table("user")
                .select("user.id", "user.name")
                .join("auth", "auth.id", "=", "user.auth_id")
                .where("auth.id", "=", 2)
                .fastPaginateNext(3, t["nextId"].getInt, key="user.id")
                .await
        echo t
        check t["previousId"].getInt == 6
        check t["currentPage"][0]["id"].getInt == 8
        check t["nextId"].getInt == 14

    test "test 17":
      asyncBlock:
        var t = rdb.table("user")
                .select("user.id", "user.name")
                .join("auth", "auth.id", "=", "user.auth_id")
                .where("auth.id", "=", 2)
                .fastPaginateNext(3, 10, key="user.id")
                .await

        t = rdb.table("user")
                .select("user.id", "user.name")
                .join("auth", "auth.id", "=", "user.auth_id")
                .where("auth.id", "=", 2)
                .fastPaginateBack(3, t["previousId"].getInt, key="user.id")
                .await
        echo t
        check t["hasPreviousId"].getBool == true
        check t["currentPage"][0]["id"].getInt == 4
        check t["nextId"].getInt == 10

    test "test 18":
      asyncBlock:
        var t = rdb.table("user")
                .select("user.id", "user.name")
                .where("id", "<", "2")
                .fastPaginate(2, key="user.id")
                .await
        echo t
        check t["currentPage"].len == 1
        check t["hasNextId"].getBool == false

    test "test 19":
      asyncBlock:
        var t = rdb.table("user")
                .select("user.id", "user.name")
                .where("id", "<", "4")
                .fastPaginate(2, key="user.id")
                .await
        echo t
        check t["currentPage"].len == 2
        check t["hasNextId"].getBool == true

    test "test 20":
      asyncBlock:
        var t = rdb.table("user")
                .select("user.id", "user.name")
                .where("id", "<", "5")
                .fastPaginate(2, key="user.id")
                .await
        echo t
        check t["currentPage"].len == 2
        check t["hasNextId"].getBool == true

    test "test 21":
      asyncBlock:
        var t = rdb.table("user")
                .select("user.id", "user.name")
                .where("id", "<", "2")
                .fastPaginateNext(2, 1, key="user.id")
                .await
        echo t
        check t["currentPage"].len == 1
        check t["hasNextId"].getBool == false

    test "test 22":
      asyncBlock:
        var t = rdb.table("user")
                .select("user.id", "user.name")
                .where("id", "<", "4")
                .fastPaginateNext(2, 1, key="user.id")
                .await
        echo t
        check t["currentPage"].len == 2
        check t["hasNextId"].getBool == true

    test "test 23":
      asyncBlock:
        var t = rdb.table("user")
                .select("user.id", "user.name")
                .where("id", "<", "5")
                .fastPaginateNext(2, 1, key="user.id")
                .await
        echo t
        check t["currentPage"].len == 2
        check t["hasNextId"].getBool == true


    test "test 24":
      asyncBlock:
        var t = rdb.table("user")
                .select("user.id", "user.name")
                .where("id", ">=", 20)
                .fastPaginateBack(2, 20, key="user.id")
                .await
        echo t
        check t["currentPage"].len == 1
        check t["hasPreviousId"].getBool == false

    test "test 25":
      asyncBlock:
        var t = rdb.table("user")
                .select("user.id", "user.name")
                .where("id", ">=", 19)
                .fastPaginateBack(2, 20, key="user.id")
                .await
        echo t
        check t["currentPage"].len == 2
        check t["hasPreviousId"].getBool == false

    test "test 26":
      asyncBlock:
        var t = rdb.table("user")
                .select("user.id", "user.name")
                .where("id", ">=", 18)
                .fastPaginateBack(2, 20, key="user.id")
                .await
        echo t
        check t["currentPage"].len == 2
        check t["hasPreviousId"].getBool == true
