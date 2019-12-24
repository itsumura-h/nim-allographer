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

  # シーダー
  RDB().table("auth").insert([
    %*{"auth": "admin"},
    %*{"auth": "user"}
  ])
  .exec()

  var insertData: seq[JsonNode]
  for i in 1..10:
    let authId = if i mod 2 == 0: 1 else: 2
    insertData.add(
      %*{
        "name": &"user{i}",
        "email": &"user{i}@gmail.com",
        "auth_id": authId
      }
    )

  RDB().table("users").insert(insertData).exec()

suite "select":
  setup:
    setup()
  test "Retrieving all row from a table":
    var t = RDB().table("users").get()
    check t[0] == %*{"id": 1, "name": "user1", "email": "user1@gmail.com", "address":newJNull(), "auth_id": 2}

  test "Retrieving a single row from a table":
    var t = RDB().table("users").where("name", "=", "user1").first()
    check t == %*{"id": 1, "name": "user1", "email": "user1@gmail.com", "address":newJNull(), "auth_id": 2}

  test "Specifying a select clause":
    var t = RDB().table("users").select("name", "email").get()
    check t[0] == %*{"name": "user1", "email": "user1@gmail.com"}

    t = RDB().table("users").select("name as user_name", "email").get()
    check t[0] == %*{"user_name": "user1", "email": "user1@gmail.com"}

  test "Using where operators":
    var t = RDB().table("users").where("auth_id", ">", "1").get()
    check t == @[
      %*{"id": 1, "name": "user1", "email": "user1@gmail.com", "address":newJNull(), "auth_id": 2},
      %*{"id": 3, "name": "user3", "email": "user3@gmail.com", "address":newJNull(), "auth_id": 2},
      %*{"id": 5, "name": "user5", "email": "user5@gmail.com", "address":newJNull(), "auth_id": 2},
      %*{"id": 7, "name": "user7", "email": "user7@gmail.com", "address":newJNull(), "auth_id": 2},
      %*{"id": 9, "name": "user9", "email": "user9@gmail.com", "address":newJNull(), "auth_id": 2}
    ]

  test "Or statements":
    var t = RDB().table("users").where("auth_id", ">", "1").orWhere("name", "=", "user2").get()
    check t == @[
      %*{"id": 1, "name": "user1", "email": "user1@gmail.com", "address":newJNull(), "auth_id": 2},
      %*{"id": 2, "name": "user2", "email": "user2@gmail.com", "address":newJNull(), "auth_id": 1},
      %*{"id": 3, "name": "user3", "email": "user3@gmail.com", "address":newJNull(), "auth_id": 2},
      %*{"id": 5, "name": "user5", "email": "user5@gmail.com", "address":newJNull(), "auth_id": 2},
      %*{"id": 7, "name": "user7", "email": "user7@gmail.com", "address":newJNull(), "auth_id": 2},
      %*{"id": 9, "name": "user9", "email": "user9@gmail.com", "address":newJNull(), "auth_id": 2}
    ]