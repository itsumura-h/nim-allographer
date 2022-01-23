discard """
  cmd: "nim c -d:reset -r $file"
"""

import unittest, json, strformat, options, asyncdispatch, random, times, os

import ../src/allographer/schema_builder
import ../src/allographer/query_builder
import ../src/allographer/connection
import connections


randomize()

proc setup() =
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
      Column().date("submit_on").nullable(),
      Column().datetime("submit_at").nullable(),
      Column().foreign("auth_id").reference("id").on("auth").onDelete(SET_NULL)
    ])
  ])

  # seeder
  asyncBlock:
    await rdb.table("auth").insert(@[
      %*{"auth": "admin"},
      %*{"auth": "user"}
    ])

    var users: seq[JsonNode]
    for i in 1..10:
      let authId = if i mod 2 == 0: 2 else: 1
      let month = if i > 9: $i else: &"0{i}"
      users.add(
        %*{
          "name": &"user{i}",
          "email": &"user{i}@gmail.com",
          "auth_id": authId,
          "submit_on": &"2020-{month}-01",
          "submit_at": &"2020-{month}-01 00:00:00",
        }
      )

    await rdb.table("users").insert(users)

block getTest:
  setup()
  asyncBlock:
    var t = await rdb.table("users").get()
    check t[0] == %*{"id":1,"name":"user1","email":"user1@gmail.com","address":newJNull(),"submit_on":"2020-01-01","submit_at":"2020-01-01 00:00:00","auth_id":1}

block getPlainTest:
  setup()
  asyncBlock:
    var t = await rdb.table("users").getPlain()
    check t[0] == @["1", "user1", "user1@gmail.com", "", "2020-01-01", "2020-01-01 00:00:00", "1"]

block perfomanceTest:
  setup()
  asyncBlock:
    var s = cpuTime()
    for i in 0..100:
      discard await rdb.table("users").get()
    echo "get...", cpuTime() - s
    s = cpuTime()
    for i in 0..100:
      discard await rdb.table("users").getPlain()
    echo "getPlain...", cpuTime() - s

block firstTest:
  setup()
  asyncBlock:
    var t = await(rdb.table("users").where("name", "=", "user1").first).get
    check t == %*{"id": 1, "name": "user1", "email": "user1@gmail.com", "address":newJNull(), "submit_on":"2020-01-01","submit_at":"2020-01-01 00:00:00", "auth_id": 1}

block firstPlainTest:
  setup()
  asyncBlock:
    var t = await rdb.table("users").firstPlain()
    check t == @["1", "user1", "user1@gmail.com", "", "2020-01-01", "2020-01-01 00:00:00", "1"]

block findTest:
  setup()
  asyncBlock:
    var t = rdb.table("users").find(1).await.get
    check t == %*{"id": 1, "name": "user1", "email": "user1@gmail.com", "address":newJNull(), "submit_on":"2020-01-01","submit_at":"2020-01-01 00:00:00", "auth_id": 1}

block findStringTest:
  setup()
  asyncBlock:
    var t = rdb.table("users").find("1").await.get
    check t == %*{"id": 1, "name": "user1", "email": "user1@gmail.com", "address":newJNull(), "submit_on":"2020-01-01","submit_at":"2020-01-01 00:00:00", "auth_id": 1}

block findPlainTest:
  setup()
  asyncBlock:
    var t = await rdb.table("users").findPlain(1)
    check t == @["1", "user1", "user1@gmail.com", "", "2020-01-01", "2020-01-01 00:00:00", "1"]

block selectTest:
  setup()
  asyncBlock:
    var t = await rdb.table("users").select("name", "email").get()
    check t[0] == %*{"name": "user1", "email": "user1@gmail.com"}

block selectAsTest:
  setup()
  asyncBlock:
    var t = await rdb.table("users").select("name as user_name", "email").get()
    check t[0] == %*{"user_name": "user1", "email": "user1@gmail.com"}

block whereTest:
  setup()
  asyncBlock:
    var t = await rdb.table("users").where("auth_id", "=", "1").get()
    check t == @[
      %*{"id":1,"name":"user1","email":"user1@gmail.com","address":newJNull(),"submit_on":"2020-01-01","submit_at":"2020-01-01 00:00:00","auth_id":1},
      %*{"id":3,"name":"user3","email":"user3@gmail.com","address":newJNull(),"submit_on":"2020-03-01","submit_at":"2020-03-01 00:00:00","auth_id":1},
      %*{"id":5,"name":"user5","email":"user5@gmail.com","address":newJNull(),"submit_on":"2020-05-01","submit_at":"2020-05-01 00:00:00","auth_id":1},
      %*{"id":7,"name":"user7","email":"user7@gmail.com","address":newJNull(),"submit_on":"2020-07-01","submit_at":"2020-07-01 00:00:00","auth_id":1},
      %*{"id":9,"name":"user9","email":"user9@gmail.com","address":newJNull(),"submit_on":"2020-09-01","submit_at":"2020-09-01 00:00:00","auth_id":1}
    ]

block orWhereTest:
  setup()
  asyncBlock:
    var t = await rdb.table("users").where("auth_id", "=", "1").orWhere("name", "=", "user2").get()
    check t == @[
      %*{"id":1,"name":"user1","email":"user1@gmail.com","address":newJNull(),"submit_on":"2020-01-01","submit_at":"2020-01-01 00:00:00","auth_id":1},
      %*{"id":2,"name":"user2","email":"user2@gmail.com","address":newJNull(),"submit_on":"2020-02-01","submit_at":"2020-02-01 00:00:00","auth_id":2},
      %*{"id":3,"name":"user3","email":"user3@gmail.com","address":newJNull(),"submit_on":"2020-03-01","submit_at":"2020-03-01 00:00:00","auth_id":1},
      %*{"id":5,"name":"user5","email":"user5@gmail.com","address":newJNull(),"submit_on":"2020-05-01","submit_at":"2020-05-01 00:00:00","auth_id":1},
      %*{"id":7,"name":"user7","email":"user7@gmail.com","address":newJNull(),"submit_on":"2020-07-01","submit_at":"2020-07-01 00:00:00","auth_id":1},
      %*{"id":9,"name":"user9","email":"user9@gmail.com","address":newJNull(),"submit_on":"2020-09-01","submit_at":"2020-09-01 00:00:00","auth_id":1}
    ]

block updateTest:
  setup()
  asyncBlock:
    await rdb.table("users").where("id", "=", 2).update(%*{"name": "John"})
    var t = await(rdb.table("users").find(2)).get
    check t["name"].getStr() == "John"

block insertIdTest:
  setup()
  asyncBlock:
    var id = await rdb.table("users").insertId(%*{"name": "John"})
    var t = await(rdb.table("users").find(id)).get
    check t["name"].getStr() == "John"

block insertsIDTest:
  setup()
  asyncBlock:
    var ids = await rdb.table("users").insertsID(@[
      %*{"name": "John"},
      %*{"email": "Paul@gmail.com"},
    ])
    var t = await(rdb.table("users").find(ids[0])).get
    check t["name"].getStr() == "John"
    t = await(rdb.table("users").find(ids[1])).get
    check t["email"].getStr() == "Paul@gmail.com"

block insertnilTest:
  setup()
  asyncBlock:
    var id = await rdb.table("users").insertId(%*{
      "name": "John",
      "email": newJNull(),
      "address": ""
    })
    var res = await rdb.table("users").find(id)
    echo res.get
    check res.get["email"] == newJNull()

    res = await rdb.table("users").where("email", "is", nil).first()
    echo res.get
    check res.get["email"] == newJNull()

block distinctTest:
  setup()
  asyncBlock:
    var t = rdb.table("users").select("id", "name").distinct()
    check t.query.hasKey("distinct") == true

block whereBetweenTest:
  setup()
  asyncBlock:
    var t = await rdb
            .table("users")
            .select("id", "name")
            .where("auth_id", "=", 1)
            .whereBetween("id", [6, 9])
            .get()
    echo t
    check t[0]["name"].getStr() == "user7"

block whereBetweenStringTest:
  setup()
  asyncBlock:
    var t = await rdb
            .table("users")
            .whereBetween("submit_at", ["2020-01-01 00:00:00", "2020-01-31 00:00:00"])
            .get()
    check t[0]["name"].getStr == "user1"

    t = await rdb
        .table("users")
        .whereBetween("submit_on", ["2020-01-01", "2020-01-31"])
        .get()
    check t[0]["name"].getStr == "user1"

block whereNotBetweenTest:
  setup()
  asyncBlock:
    var t = await rdb
            .table("users")
            .select("id", "name")
            .where("auth_id", "=", 1)
            .whereNotBetween("id", [1, 4])
            .get()
    check t[0]["name"].getStr() == "user5"

block whereNotBetweenStringTest:
  setup()
  asyncBlock:
    var t = await rdb
            .table("users")
            .whereNotBetween("submit_at", ["2020-2-1 00:00:00", "2020-12-31 00:00:00"])
            .get()
    check t[0]["name"].getStr == "user1"

    t = await rdb
        .table("users")
        .whereNotBetween("submit_on", ["2020-2-1", "2020-12-31"])
        .get()
    check t[0]["name"].getStr == "user1"

block whereInTest:
  setup()
  asyncBlock:
    var t = await rdb
            .table("users")
            .select("id", "name")
            .whereBetween("id", [4, 10])
            .whereIn("id", @[5, 6, 7])
            .get()
    echo t
    check t[0]["name"].getStr() == "user5"

block whereNotInTest:
  setup()
  asyncBlock:
    var t = await rdb
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

block whereNullTest:
  setup()
  asyncBlock:
    await rdb.table("users").insert(%*{"email": "user11@gmail.com"})
    var t = await rdb
            .table("users")
            .select("id", "name", "email")
            .whereNull("name")
            .get()
    echo t
    check t[0]["id"].getInt() == 11

block groupByTest:
  setup()
  asyncBlock:
    var t = await rdb
            .table("users")
            .select("max(id)")
            .groupBy("auth_id")
            .get()
    echo t
    if rdb.conn.driver == SQLite3:
      check t[0]["max(id)"].getStr() == "9"
    if rdb.conn.driver == MySQL:
      check t[0]["max(id)"].getInt() == 9
    if rdb.conn.driver == PostgreSQL:
      check t[0]["max"].getInt() == 9

block havingTest:
  setup()
  asyncBlock:
    var t = await rdb
            .table("users")
            .select("id", "name")
            .groupBy("auth_id")
            .groupBy("id")
            .having("auth_id", "=", 1)
            .get()
    echo t
    check t[0]["id"].getInt() == 1

block orderByTest:
  setup()
  asyncBlock:
    var t = await rdb.table("users")
            .orderBy("auth_id", Asc)
            .orderBy("id", Desc)
            .get()
    echo t
    check t[0]["id"].getInt() == 9

block joinTest:
  setup()
  asyncBlock:
    var t = await rdb.table("users")
            .select("users.id", "users.name")
            .join("auth", "auth.id", "=", "users.auth_id")
            .where("auth.id", "=", "2")
            .get()
    echo t
    check t[0]["name"].getStr() == "user2"

block leftJoinTest:
  setup()
  asyncBlock:
    await rdb.table("users").insert(%*{
      "name": "user11"
    })
    var t = await rdb.table("users")
            .select("users.id", "users.name", "users.auth_id")
            .leftJoin("auth", "auth.id", "=", "users.auth_id")
            .orderBy("users.id", Desc)
            .get()
    echo t
    check t[0]["name"].getStr() == "user11"
    check t[0]["auth_id"] == newJNull()

block resultIsNullTest:
  setup()
  asyncBlock:
    check await(rdb.table("users").find(50)).isSome == false
    check newSeq[JsonNode](0) == await rdb.table("users").where("id", "=", 50).get()

block deleteTest:
  setup()
  asyncBlock:
    echo await rdb.table("users").get()
    await rdb.table("users").delete(1)
    check  await(rdb.table("users").find(1)).isSome == false

block deleteWithWhereTest:
  setup()
  asyncBlock:
    await rdb.table("users").where("name", "=", "user2").delete()
    check await(rdb.table("users").find(2)).isSome == false

block rawQueryTest:
  setup()
  asyncBlock:
    let sql = "SELECT * FROM users WHERE id = ?"
    var res = await rdb.raw(sql, "1").getRaw()
    echo res
    check res[0]["name"].getStr == "user1"
