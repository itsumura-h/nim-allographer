import unittest, json, strformat

import ../src/allographer/schema_builder
import ../src/allographer/query_builder


proc setup() =
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
  for i in 1..10:
    let authId = if i mod 2 == 0: 2 else: 1
    insertData.add(
      %*{
        "name": &"user{i}",
        "email": &"user{i}@gmail.com",
        "auth_id": authId
      }
    )

  RDB().table("users").insert(insertData)


suite "select":
  setup:
    setup()
  test "get()":
    var t = RDB().table("users").get()
    check t[0] == %*{"id": 1, "name": "user1", "email": "user1@gmail.com", "address":newJNull(), "auth_id": 1}

  test "first()":
    var t = RDB().table("users").where("name", "=", "user1").first()
    check t == %*{"id": 1, "name": "user1", "email": "user1@gmail.com", "address":newJNull(), "auth_id": 1}

  test "select()":
    var t = RDB().table("users").select("name", "email").get()
    check t[0] == %*{"name": "user1", "email": "user1@gmail.com"}
  
  test "select(as)":
    var t = RDB().table("users").select("name as user_name", "email").get()
    check t[0] == %*{"user_name": "user1", "email": "user1@gmail.com"}

  test "where":
    var t = RDB().table("users").where("auth_id", "=", "1").get()
    check t == @[
      %*{"id": 1, "name": "user1", "email": "user1@gmail.com", "address":newJNull(), "auth_id": 1},
      %*{"id": 3, "name": "user3", "email": "user3@gmail.com", "address":newJNull(), "auth_id": 1},
      %*{"id": 5, "name": "user5", "email": "user5@gmail.com", "address":newJNull(), "auth_id": 1},
      %*{"id": 7, "name": "user7", "email": "user7@gmail.com", "address":newJNull(), "auth_id": 1},
      %*{"id": 9, "name": "user9", "email": "user9@gmail.com", "address":newJNull(), "auth_id": 1}
    ]

  test "orWhere":
    var t = RDB().table("users").where("auth_id", "=", "1").orWhere("name", "=", "user2").get()
    check t == @[
      %*{"id": 1, "name": "user1", "email": "user1@gmail.com", "address":newJNull(), "auth_id": 1},
      %*{"id": 2, "name": "user2", "email": "user2@gmail.com", "address":newJNull(), "auth_id": 2},
      %*{"id": 3, "name": "user3", "email": "user3@gmail.com", "address":newJNull(), "auth_id": 1},
      %*{"id": 5, "name": "user5", "email": "user5@gmail.com", "address":newJNull(), "auth_id": 1},
      %*{"id": 7, "name": "user7", "email": "user7@gmail.com", "address":newJNull(), "auth_id": 1},
      %*{"id": 9, "name": "user9", "email": "user9@gmail.com", "address":newJNull(), "auth_id": 1}
    ]

  test "update()":
    RDB().table("users").where("id", "=", 2).update(%*{"name": "John"})
    var t = RDB().table("users").find(2)
    check t["name"].getStr() == "John"

  test "insertID()":
    var id = RDB().table("users").insertID(%*{"name": "John"})
    var t = RDB().table("users").find(id)
    check t["name"].getStr() == "John"

  test "insertsID()":
    var ids = RDB().table("users").insertsID([
      %*{"name": "John"},
      %*{"email": "Paul@gmail.com"},
    ])
    var t = RDB().table("users").find(ids[0])
    check t["name"].getStr() == "John"
    t = RDB().table("users").find(ids[1])
    check t["email"].getStr() == "Paul@gmail.com"

  test "distinct":
    var t = RDB().table("users").select("id", "name").distinct()
    check t.query.hasKey("distinct") == true

  test "whereBetween()":
    var t = RDB()
            .table("users")
            .select("id", "name")
            .where("auth_id", "=", 1)
            .whereBetween("id", [6, 9])
            .get()
    check t[0]["name"].getStr() == "user7"

  test "whereNotBetween()":
    var t = RDB()
            .table("users")
            .select("id", "name")
            .where("auth_id", "=", 1)
            .whereNotBetween("id", [1, 4])
            .get()
    check t[0]["name"].getStr() == "user5"