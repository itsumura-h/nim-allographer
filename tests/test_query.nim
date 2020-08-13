import unittest, json, strformat

import ../src/allographer/schema_builder
import ../src/allographer/query_builder
from ../src/allographer/connection import getDriver

proc setup() =
  schema([
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
  rdb().table("auth").insert([
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

  rdb().table("users").insert(users)

suite "connection":
  test "1":
    let rdb1 = rdb()
    echo rdb1.repr
    let rdb2 = rdb()
    echo rdb2.repr
    echo rdb1.db.repr
    echo rdb2.db.repr
    check rdb().db.repr == rdb().db.repr

suite "select":
  setup:
    setup()
  test "get()":
    var t = rdb().table("users").get()
    check t[0] == %*{"id": 1, "name": "user1", "email": "user1@gmail.com", "address":newJNull(), "auth_id": 1}

  test "getPlain()":
    var t = rdb().table("users").getPlain()
    check t[0] == @["1", "user1", "user1@gmail.com", "", "1"]

  test "first()":
    var t = rdb().table("users").where("name", "=", "user1").first()
    check t == %*{"id": 1, "name": "user1", "email": "user1@gmail.com", "address":newJNull(), "auth_id": 1}

  test "firstPlain()":
    var t = rdb().table("users").firstPlain()
    check t == @["1", "user1", "user1@gmail.com", "", "1"]

  test "find()":
    var t = rdb().table("users").find(1)
    check t == %*{"id": 1, "name": "user1", "email": "user1@gmail.com", "address":newJNull(), "auth_id": 1}

  test "findPlain()":
    var t = rdb().table("users").findPlain(1)
    check t == @["1", "user1", "user1@gmail.com", "", "1"]

  test "select()":
    var t = rdb().table("users").select("name", "email").get()
    check t[0] == %*{"name": "user1", "email": "user1@gmail.com"}

  test "select(as)":
    var t = rdb().table("users").select("name as user_name", "email").get()
    check t[0] == %*{"user_name": "user1", "email": "user1@gmail.com"}

  test "where":
    var t = rdb().table("users").where("auth_id", "=", "1").get()
    check t == @[
      %*{"id": 1, "name": "user1", "email": "user1@gmail.com", "address":newJNull(), "auth_id": 1},
      %*{"id": 3, "name": "user3", "email": "user3@gmail.com", "address":newJNull(), "auth_id": 1},
      %*{"id": 5, "name": "user5", "email": "user5@gmail.com", "address":newJNull(), "auth_id": 1},
      %*{"id": 7, "name": "user7", "email": "user7@gmail.com", "address":newJNull(), "auth_id": 1},
      %*{"id": 9, "name": "user9", "email": "user9@gmail.com", "address":newJNull(), "auth_id": 1}
    ]

  test "orWhere":
    var t = rdb().table("users").where("auth_id", "=", "1").orWhere("name", "=", "user2").get()
    check t == @[
      %*{"id": 1, "name": "user1", "email": "user1@gmail.com", "address":newJNull(), "auth_id": 1},
      %*{"id": 2, "name": "user2", "email": "user2@gmail.com", "address":newJNull(), "auth_id": 2},
      %*{"id": 3, "name": "user3", "email": "user3@gmail.com", "address":newJNull(), "auth_id": 1},
      %*{"id": 5, "name": "user5", "email": "user5@gmail.com", "address":newJNull(), "auth_id": 1},
      %*{"id": 7, "name": "user7", "email": "user7@gmail.com", "address":newJNull(), "auth_id": 1},
      %*{"id": 9, "name": "user9", "email": "user9@gmail.com", "address":newJNull(), "auth_id": 1}
    ]

  test "update()":
    rdb().table("users").where("id", "=", 2).update(%*{"name": "John"})
    var t = rdb().table("users").find(2)
    check t["name"].getStr() == "John"

  test "insertID()":
    var id = rdb().table("users").insertID(%*{"name": "John"})
    var t = rdb().table("users").find(id)
    check t["name"].getStr() == "John"

  test "insertsID()":
    var ids = rdb().table("users").insertsID([
      %*{"name": "John"},
      %*{"email": "Paul@gmail.com"},
    ])
    var t = rdb().table("users").find(ids[0])
    check t["name"].getStr() == "John"
    t = rdb().table("users").find(ids[1])
    check t["email"].getStr() == "Paul@gmail.com"

  test "distinct":
    var t = rdb().table("users").select("id", "name").distinct()
    check t.query.hasKey("distinct") == true

  test "whereBetween()":
    var t = rdb()
            .table("users")
            .select("id", "name")
            .where("auth_id", "=", 1)
            .whereBetween("id", [6, 9])
            .get()
    echo t
    check t[0]["name"].getStr() == "user7"

  test "whereNotBetween()":
    var t = rdb()
            .table("users")
            .select("id", "name")
            .where("auth_id", "=", 1)
            .whereNotBetween("id", [1, 4])
            .get()
    check t[0]["name"].getStr() == "user5"

  test "whereIn()":
    var t = rdb()
            .table("users")
            .select("id", "name")
            .whereBetween("id", [4, 10])
            .whereIn("id", @[5, 6, 7])
            .get()
    echo t
    check t[0]["name"].getStr() == "user5"

  test "whereNotIn()":
    var t = rdb()
            .table("users")
            .select("id", "name")
            .whereBetween("id", [4, 10])
            .whereNotIn("id", @[5, 6, 7])
            .get()
    echo t
    check t == @[
      %*{"id":4, "name": "user4"},
      %*{"id":8, "name": "user8"},
      %*{"id":9, "name": "user9"},
      %*{"id":10, "name": "user10"},
    ]

  test "whereNull()":
    rdb().table("users").insert(%*{"email": "user11@gmail.com"})
    var t = rdb()
            .table("users")
            .select("id", "name", "email")
            .whereNull("name")
            .get()
    echo t
    check t[0]["id"].getInt() == 11

  test "groupBy()":
    var t = rdb()
            .table("users")
            .select("max(id)")
            .groupBy("auth_id")
            .get()
    echo t
    let DRIVER = connection.getDriver()
    when DRIVER is "sqlite":
      check t[0]["max(id)"].getStr() == "9"
    when DRIVER is "mysql":
      check t[0]["max(id)"].getInt() == 9
    when DRIVER is "postgres":
      check t[0]["max"].getInt() == 9

  test "having()":
    var t = rdb()
            .table("users")
            .select("id", "name")
            .groupBy("auth_id")
            .groupBy("id")
            .having("auth_id", "=", 1)
            .get()
    echo t
    check t[0]["id"].getInt() == 1

  test "orderBy()":
    var t = rdb().table("users")
            .orderBy("auth_id", Asc)
            .orderBy("id", Desc)
            .get()
    echo t
    check t[0]["id"].getInt() == 9

  test "join()":
    var t = rdb().table("users")
            .select("users.id", "users.name")
            .join("auth", "auth.id", "=", "users.auth_id")
            .where("auth.id", "=", "2")
            .get()
    echo t
    check t[0]["name"].getStr() == "user2"

  test "leftJoin()":
    rdb().table("users").insert(%*{
      "name": "user11"
    })
    var t = rdb().table("users")
            .select("users.id", "users.name", "users.auth_id")
            .leftJoin("auth", "auth.id", "=", "users.auth_id")
            .orderBy("users.id", Desc)
            .get()
    echo t
    check t[0]["name"].getStr() == "user11"
    check t[0]["auth_id"] == newJNull()

  test "result is null":
    check newJNull() == rdb().table("users").find(50)
    check newSeq[JsonNode](0) == rdb().table("users").where("id", "=", 50).get()

  test "delete":
    echo rdb().table("users").get()
    rdb().table("users").delete(1)
    check  rdb().table("users").find(1) == newJNull()

  test "delete with where":
    rdb().table("users").where("name", "=", "user2").delete()
    check rdb().table("users").find(2) == newJNull()
