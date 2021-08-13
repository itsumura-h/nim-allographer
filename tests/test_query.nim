import unittest, json, strformat, options, asyncdispatch, random

import ../src/allographer/schema_builder
import ../src/allographer/query_builder
import connections

randomize()

proc setup() =
  db.schema([
    table("auth",[
      Column().increments("id"),
      Column().string("auth")
    ], reset=true),
    table("users",[
      Column().increments("id"),
      Column().string("name").nullable(),
      Column().string("email").nullable(),
      Column().string("address").nullable(),
      Column().foreign("auth_id").reference("id").on("auth").onDelete(SET_NULL)
    ], reset=true)
  ])

  # seeder
  asyncBlock:
    await db.table("auth").insert(@[
      %*{"auth": "admin"},
      %*{"auth": "user"}
    ])

    var users: seq[JsonNode]
    for i in 1..10:
      let authId = if i mod 2 == 0: 2 else: 1
      users.add(
        %*{
          "name": &"user{i}",
          "email": &"user{i}@gmail.com",
          "auth_id": authId
        }
      )

    await db.table("users").insert(users)

suite "select":
  setup:
    setup()
  # test "get()":
  #   asyncBlock:
  #     var t = await db.table("users").get()
  #     check t[0] == %*{"id": 1, "name": "user1", "email": "user1@gmail.com", "address":newJNull(), "auth_id": 1}

  # test "getPlain()":
  #   asyncBlock:
  #     var t = await db.table("users").getPlain()
  #     check t[0] == @["1", "user1", "user1@gmail.com", "", "1"]

  # test "first()":
  #   asyncBlock:
  #     var t = await(db.table("users").where("name", "=", "user1").first).get
  #     check t == %*{"id": 1, "name": "user1", "email": "user1@gmail.com", "address":newJNull(), "auth_id": 1}

  # test "firstPlain()":
  #   asyncBlock:
  #     var t = await db.table("users").firstPlain()
  #     check t == @["1", "user1", "user1@gmail.com", "", "1"]

  # test "find()":
  #   asyncBlock:
  #     var t = await(db.table("users").find(1)).get
  #     check t == %*{"id": 1, "name": "user1", "email": "user1@gmail.com", "address":newJNull(), "auth_id": 1}

  # test "findPlain()":
  #   asyncBlock:
  #     var t = await db.table("users").findPlain(1)
  #     check t == @["1", "user1", "user1@gmail.com", "", "1"]

  # test "select()":
  #   asyncBlock:
  #     var t = await db.table("users").select("name", "email").get()
  #     check t[0] == %*{"name": "user1", "email": "user1@gmail.com"}

  # test "select(as)":
  #   asyncBlock:
  #     var t = await db.table("users").select("name as user_name", "email").get()
  #     check t[0] == %*{"user_name": "user1", "email": "user1@gmail.com"}

  # test "where":
  #   asyncBlock:
  #     var t = await db.table("users").where("auth_id", "=", "1").get()
  #     check t == @[
  #       %*{"id": 1, "name": "user1", "email": "user1@gmail.com", "address":newJNull(), "auth_id": 1},
  #       %*{"id": 3, "name": "user3", "email": "user3@gmail.com", "address":newJNull(), "auth_id": 1},
  #       %*{"id": 5, "name": "user5", "email": "user5@gmail.com", "address":newJNull(), "auth_id": 1},
  #       %*{"id": 7, "name": "user7", "email": "user7@gmail.com", "address":newJNull(), "auth_id": 1},
  #       %*{"id": 9, "name": "user9", "email": "user9@gmail.com", "address":newJNull(), "auth_id": 1}
  #     ]

  # test "orWhere":
  #   asyncBlock:
  #     var t = await db.table("users").where("auth_id", "=", "1").orWhere("name", "=", "user2").get()
  #     check t == @[
  #       %*{"id": 1, "name": "user1", "email": "user1@gmail.com", "address":newJNull(), "auth_id": 1},
  #       %*{"id": 2, "name": "user2", "email": "user2@gmail.com", "address":newJNull(), "auth_id": 2},
  #       %*{"id": 3, "name": "user3", "email": "user3@gmail.com", "address":newJNull(), "auth_id": 1},
  #       %*{"id": 5, "name": "user5", "email": "user5@gmail.com", "address":newJNull(), "auth_id": 1},
  #       %*{"id": 7, "name": "user7", "email": "user7@gmail.com", "address":newJNull(), "auth_id": 1},
  #       %*{"id": 9, "name": "user9", "email": "user9@gmail.com", "address":newJNull(), "auth_id": 1}
  #     ]

  # test "update()":
  #   asyncBlock:
  #     await db.table("users").where("id", "=", 2).update(%*{"name": "John"})
  #     var t = await(db.table("users").find(2)).get
  #     check t["name"].getStr() == "John"

  # test "insertId()":
  #   asyncBlock:
  #     var id = await db.table("users").insertId(%*{"name": "John"})
  #     var t = await(db.table("users").find(id)).get
  #     check t["name"].getStr() == "John"

  # test "insertsID()":
  #   asyncBlock:
  #     var ids = await db.table("users").insertsID(@[
  #       %*{"name": "John"},
  #       %*{"email": "Paul@gmail.com"},
  #     ])
  #     var t = await(db.table("users").find(ids[0])).get
  #     check t["name"].getStr() == "John"
  #     t = await(db.table("users").find(ids[1])).get
  #     check t["email"].getStr() == "Paul@gmail.com"

  # test "insert nil":
  #   asyncBlock:
  #     var id = await db.table("users").insertId(%*{
  #       "name": "John",
  #       "email": nil,
  #       "address": ""
  #     })
  #     var res = await db.table("users").find(id)
  #     echo res.get
  #     check res.get["email"] == newJNull()

  #     res = await db.table("users").where("email", "is", nil).first()
  #     echo res.get
  #     check res.get["email"] == newJNull()

  # test "distinct":
  #   asyncBlock:
  #     var t = db.table("users").select("id", "name").distinct()
  #     check t.query.hasKey("distinct") == true

  # test "whereBetween()":
  #   asyncBlock:
  #     var t = await db
  #             .table("users")
  #             .select("id", "name")
  #             .where("auth_id", "=", 1)
  #             .whereBetween("id", [6, 9])
  #             .get()
  #     echo t
  #     check t[0]["name"].getStr() == "user7"

  # test "whereNotBetween()":
  #   asyncBlock:
  #     var t = await db
  #             .table("users")
  #             .select("id", "name")
  #             .where("auth_id", "=", 1)
  #             .whereNotBetween("id", [1, 4])
  #             .get()
  #     check t[0]["name"].getStr() == "user5"

  # test "whereIn()":
  #   asyncBlock:
  #     var t = await db
  #             .table("users")
  #             .select("id", "name")
  #             .whereBetween("id", [4, 10])
  #             .whereIn("id", @[5, 6, 7])
  #             .get()
  #     echo t
  #     check t[0]["name"].getStr() == "user5"

  # test "whereNotIn()":
  #   asyncBlock:
  #     var t = await db
  #             .table("users")
  #             .select("id", "name")
  #             .whereBetween("id", [4, 10])
  #             .whereNotIn("id", @[5, 6, 7])
  #             .get()
  #     echo t
  #     check t == @[
  #       %*{"id":4, "name": "user4"},
  #       %*{"id":8, "name": "user8"},
  #       %*{"id":9, "name": "user9"},
  #       %*{"id":10, "name": "user10"},
  #     ]

  # test "whereNull()":
  #   asyncBlock:
  #     await db.table("users").insert(%*{"email": "user11@gmail.com"})
  #     var t = await db
  #             .table("users")
  #             .select("id", "name", "email")
  #             .whereNull("name")
  #             .get()
  #     echo t
  #     check t[0]["id"].getInt() == 11

  # test "groupBy()":
  #   asyncBlock:
  #     var t = await db
  #             .table("users")
  #             .select("max(id)")
  #             .groupBy("auth_id")
  #             .get()
  #     echo t
  #     if db.driver == SQLite3:
  #       check t[0]["max(id)"].getStr() == "9"
  #     if db.driver == MySQL:
  #       check t[0]["max(id)"].getInt() == 9
  #     if db.driver == PostgreSQL:
  #       check t[0]["max"].getInt() == 9

  # test "having()":
  #   asyncBlock:
  #     var t = await db
  #             .table("users")
  #             .select("id", "name")
  #             .groupBy("auth_id")
  #             .groupBy("id")
  #             .having("auth_id", "=", 1)
  #             .get()
  #     echo t
  #     check t[0]["id"].getInt() == 1

  # test "orderBy()":
  #   asyncBlock:
  #     var t = await db.table("users")
  #             .orderBy("auth_id", Asc)
  #             .orderBy("id", Desc)
  #             .get()
  #     echo t
  #     check t[0]["id"].getInt() == 9

  # test "join()":
  #   asyncBlock:
  #     var t = await db.table("users")
  #             .select("users.id", "users.name")
  #             .join("auth", "auth.id", "=", "users.auth_id")
  #             .where("auth.id", "=", "2")
  #             .get()
  #     echo t
  #     check t[0]["name"].getStr() == "user2"

  # test "leftJoin()":
  #   asyncBlock:
  #     await db.table("users").insert(%*{
  #       "name": "user11"
  #     })
  #     var t = await db.table("users")
  #             .select("users.id", "users.name", "users.auth_id")
  #             .leftJoin("auth", "auth.id", "=", "users.auth_id")
  #             .orderBy("users.id", Desc)
  #             .get()
  #     echo t
  #     check t[0]["name"].getStr() == "user11"
  #     check t[0]["auth_id"] == newJNull()

  # test "result is null":
  #   asyncBlock:
  #     check await(db.table("users").find(50)).isSome == false
  #     check newSeq[JsonNode](0) == await db.table("users").where("id", "=", 50).get()

  # test "delete":
  #   asyncBlock:
  #     echo await db.table("users").get()
  #     await db.table("users").delete(1)
  #     check  await(db.table("users").find(1)).isSome == false

  # test "delete with where":
  #   asyncBlock:
  #     await db.table("users").where("name", "=", "user2").delete()
  #     check await(db.table("users").find(2)).isSome == false

  # test "raw query":
  #   asyncBlock:
  #     let sql = "SELECT * FROM users WHERE id = ?"
  #     var res = await db.raw(sql, "1").getRaw()
  #     echo res
  #     check res[0]["name"].getStr == "user1"

  test "prepare":
    asyncBlock:
      let sql = "SELECT * FROM users WHERE id = $1"
      let prepared = await db.prepare(sql)
      var futures = newSeq[Future[(seq[Row], DbRows)]]()
      for i in 0..500:
        let n = rand(1..10)
        futures.add(prepared.query(@[$n]))
      let results = await all(futures)
      prepared.close()
      for res in results:
        echo res[0]
