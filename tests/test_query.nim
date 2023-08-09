discard """
  cmd: "nim c -d:reset -r $file"
"""

import std/unittest
import std/json
import std/strformat
import std/options
import std/asyncdispatch
import std/random
import std/times
import ../src/allographer/schema_builder
import ../src/allographer/query_builder
import ../src/allographer/connection
import ./connections


randomize()

# =============================================================================
# test
# =============================================================================

proc setup(rdb:SqliteConnections|PostgresConnections) =
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
      Column.date("submit_on").nullable(),
      Column.datetime("submit_at").nullable(),
      Column.foreign("auth_id").reference("id").on("auth").onDelete(SET_NULL).nullable()
    ])
  ])

  # seeder
  seeder(rdb, "auth"):
    rdb.table("auth").insert(@[
      %*{"auth": "admin"},
      %*{"auth": "user"}
    ])
    .waitFor

  seeder(rdb, "user"):
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

    rdb.table("user").insert(users).waitFor


runAllDb([sqlite], rdb):
  suite($rdb & " test query get"):
    setup(rdb)

    test("get"):
      let t = rdb.table("user").get().waitFor
      let expect = %*{"id":1,"name":"user1","email":"user1@gmail.com","address":newJNull(),"submit_on":"2020-01-01","submit_at":"2020-01-01 00:00:00","auth_id":1}
      echo t[0]
      echo expect
      check t[0] == expect

    test("getPlain"):
      let t = rdb.table("user").getPlain().waitFor
      check t[0] == @["1", "user1", "user1@gmail.com", "", "2020-01-01", "2020-01-01 00:00:00", "1"]

    test("first"):
      var t = waitFor(rdb.table("user").where("name", "=", "user1").first).get
      check t == %*{"id": 1, "name": "user1", "email": "user1@gmail.com", "address":newJNull(), "submit_on":"2020-01-01","submit_at":"2020-01-01 00:00:00", "auth_id": 1}

    test("firstPlain"):
      var t = rdb.table("user").firstPlain().waitFor
      check t == @["1", "user1", "user1@gmail.com", "", "2020-01-01", "2020-01-01 00:00:00", "1"]
      
    test("find"):
      var t = rdb.table("user").find(1).waitFor.get
      check t == %*{"id": 1, "name": "user1", "email": "user1@gmail.com", "address":newJNull(), "submit_on":"2020-01-01","submit_at":"2020-01-01 00:00:00", "auth_id": 1}

    test("findString"):
      var t = rdb.table("user").find("1").waitFor.get
      check t == %*{"id": 1, "name": "user1", "email": "user1@gmail.com", "address":newJNull(), "submit_on":"2020-01-01","submit_at":"2020-01-01 00:00:00", "auth_id": 1}

    test("findPlain"):
      var t = rdb.table("user").findPlain(1).waitFor
      check t == @["1", "user1", "user1@gmail.com", "", "2020-01-01", "2020-01-01 00:00:00", "1"]

    test("select"):
      var t = rdb.select("name", "email").table("user").get().waitFor
      check t[0] == %*{"name": "user1", "email": "user1@gmail.com"}

    test("selectAs"):
      var t = rdb.select("name as user_name", "email").table("user").get().waitFor
      check t[0] == %*{"user_name": "user1", "email": "user1@gmail.com"}

    test("selectLike"):
      var t = rdb.select("email").table("user").where("email", "LIKE", "%10%").get().waitFor
      check t == @[%*{"email":"user10@gmail.com"}]
      t = rdb.select("email").table("user").where("email", "LIKE", "user10%").get().waitFor
      check t == @[%*{"email":"user10@gmail.com"}]
      t = rdb.select("email").table("user").where("email", "LIKE", "%10@gmail.com%").get().waitFor
      check t == @[%*{"email":"user10@gmail.com"}]

    test("where"):
      var t = rdb.table("user").where("auth_id", "=", "1").get().waitFor
      check t == @[
        %*{"id":1,"name":"user1","email":"user1@gmail.com","address":newJNull(),"submit_on":"2020-01-01","submit_at":"2020-01-01 00:00:00","auth_id":1},
        %*{"id":3,"name":"user3","email":"user3@gmail.com","address":newJNull(),"submit_on":"2020-03-01","submit_at":"2020-03-01 00:00:00","auth_id":1},
        %*{"id":5,"name":"user5","email":"user5@gmail.com","address":newJNull(),"submit_on":"2020-05-01","submit_at":"2020-05-01 00:00:00","auth_id":1},
        %*{"id":7,"name":"user7","email":"user7@gmail.com","address":newJNull(),"submit_on":"2020-07-01","submit_at":"2020-07-01 00:00:00","auth_id":1},
        %*{"id":9,"name":"user9","email":"user9@gmail.com","address":newJNull(),"submit_on":"2020-09-01","submit_at":"2020-09-01 00:00:00","auth_id":1}
      ]

    test("orWhere"):
      var t = rdb.table("user").where("auth_id", "=", "1").orWhere("name", "=", "user2").get().waitFor
      check t == @[
        %*{"id":1,"name":"user1","email":"user1@gmail.com","address":newJNull(),"submit_on":"2020-01-01","submit_at":"2020-01-01 00:00:00","auth_id":1},
        %*{"id":2,"name":"user2","email":"user2@gmail.com","address":newJNull(),"submit_on":"2020-02-01","submit_at":"2020-02-01 00:00:00","auth_id":2},
        %*{"id":3,"name":"user3","email":"user3@gmail.com","address":newJNull(),"submit_on":"2020-03-01","submit_at":"2020-03-01 00:00:00","auth_id":1},
        %*{"id":5,"name":"user5","email":"user5@gmail.com","address":newJNull(),"submit_on":"2020-05-01","submit_at":"2020-05-01 00:00:00","auth_id":1},
        %*{"id":7,"name":"user7","email":"user7@gmail.com","address":newJNull(),"submit_on":"2020-07-01","submit_at":"2020-07-01 00:00:00","auth_id":1},
        %*{"id":9,"name":"user9","email":"user9@gmail.com","address":newJNull(),"submit_on":"2020-09-01","submit_at":"2020-09-01 00:00:00","auth_id":1}
      ]

    test("columns"):
      let columns = rdb.table("user").columns().waitFor
      check columns == @["id", "name", "email", "address", "submit_on", "submit_at", "auth_id"]
  
  suite($rdb & " test query update"):
    setup:
      setup(rdb)

    test("updateTest"):
      rdb.table("user").where("id", "=", 2).update(%*{"name": "John"}).waitFor
      var t = rdb.table("user").find(2).waitFor().get()
      check t["name"].getStr() == "John"

  suite($rdb & " test query insert"):
    setup:
      setup(rdb)

    test("insertId"):
      var id = rdb.table("user").insertId(%*{"name": "John"}).waitFor
      echo id
      let t = rdb.table("user").find(id).waitFor().get()
      check t["name"].getStr() == "John"

    test("insertsId"):
      echo rdb.table("user").orderBy("id", Desc).first().waitFor
      var ids = rdb.table("user").insertsId(@[
        %*{"name": "John"},
        %*{"email": "Paul@gmail.com"},
      ])
      .waitFor
      var t = rdb.table("user").find(ids[0]).waitFor.get
      echo "=== t"
      echo t
      check t["name"].getStr() == "John"
      t = waitFor(rdb.table("user").find(ids[1])).get
      check t["email"].getStr() == "Paul@gmail.com"

    test("insertNil"):
      var id = rdb.table("user").insertId(%*{
        "name": "John",
        "email": newJNull(),
        "address": ""
      })
      .waitFor
      var res = rdb.table("user").find(id).waitFor
      echo res.get
      check res.get["email"] == newJNull()

      res = rdb.table("user").where("email", "is", nil).first().waitFor
      echo res.get
      check res.get["email"] == newJNull()
        
    # test("whereBetweenTest"):
    #   asyncBlock:
    #     rdb.raw("BEGIN").exec().waitFor
    #     var t = rdb
    #             .select("id", "name")
    #             .table("user")
    #             .where("auth_id", "=", 1)
    #             .whereBetween("id", [6, 9])
    #             .get()
    #             .waitFor
    #     echo t
    #     check t[0]["name"].getStr() == "user7"
    #     rdb.raw("ROLLBACK").exec().waitFor

    # test("whereBetweenStringTest"):
    #   asyncBlock:
    #     rdb.raw("BEGIN").exec().waitFor
    #     var t = rdb
    #             .table("user")
    #             .whereBetween("submit_at", ["2020-01-01 00:00:00", "2020-01-31 00:00:00"])
    #             .get()
    #             .waitFor
    #     check t[0]["name"].getStr == "user1"

    #     t = rdb
    #         .table("user")
    #         .whereBetween("submit_on", ["2020-01-01", "2020-01-31"])
    #         .get()
    #         .waitFor
    #     check t[0]["name"].getStr == "user1"
    #     rdb.raw("ROLLBACK").exec().waitFor

    # test("whereNotBetweenTest"):
    #   asyncBlock:
    #     rdb.raw("BEGIN").exec().waitFor
    #     var t = rdb
    #             .select("id", "name")
    #             .table("user")
    #             .where("auth_id", "=", 1)
    #             .whereNotBetween("id", [1, 4])
    #             .get()
    #             .waitFor
    #     check t[0]["name"].getStr() == "user5"
    #     rdb.raw("ROLLBACK").exec().waitFor

    # test("whereNotBetweenStringTest"):
    #   asyncBlock:
    #     rdb.raw("BEGIN").exec().waitFor
    #     var t = rdb
    #             .table("user")
    #             .whereNotBetween("submit_at", ["2020-2-1 00:00:00", "2020-12-31 00:00:00"])
    #             .get()
    #             .waitFor
    #     check t[0]["name"].getStr == "user1"

    #     t = rdb
    #         .table("user")
    #         .whereNotBetween("submit_on", ["2020-2-1", "2020-12-31"])
    #         .get()
    #         .waitFor
    #     check t[0]["name"].getStr == "user1"
    #     rdb.raw("ROLLBACK").exec().waitFor

    # test("whereInTest"):
    #   asyncBlock:
    #     rdb.raw("BEGIN").exec().waitFor
    #     var t = rdb
    #             .select("id", "name")
    #             .table("user")
    #             .whereBetween("id", [4, 10])
    #             .whereIn("id", @[5, 6, 7])
    #             .get()
    #             .waitFor
    #     echo t
    #     check t[0]["name"].getStr() == "user5"
        
    #     t = rdb
    #         .select("id", "name")
    #         .table("user")
    #         .whereBetween("id", [4, 10])
    #         .whereIn("name", @["user5", "user6", "user7"])
    #         .get()
    #         .waitFor
    #     check t[0]["name"].getStr() == "user5"
    #     rdb.raw("ROLLBACK").exec().waitFor

    # test("whereNotInTest"):
    #   asyncBlock:
    #     rdb.raw("BEGIN").exec().waitFor
    #     var t = rdb
    #             .select("id", "name")
    #             .table("user")
    #             .whereBetween("id", [4, 10])
    #             .whereNotIn("id", @[5, 6, 7])
    #             .get()
    #             .waitFor
    #     echo t
    #     check t == @[
    #       %*{"id":4, "name": "user4"},
    #       %*{"id":8, "name": "user8"},
    #       %*{"id":9, "name": "user9"},
    #       %*{"id":10, "name": "user10"},
    #     ]
        
    #     t = rdb
    #         .select("id", "name")
    #         .table("user")
    #         .whereBetween("id", [4, 10])
    #         .whereNotIn("name", @["user5", "user6", "user7"])
    #         .get()
    #         .waitFor
    #     echo t
    #     check t == @[
    #       %*{"id":4, "name": "user4"},
    #       %*{"id":8, "name": "user8"},
    #       %*{"id":9, "name": "user9"},
    #       %*{"id":10, "name": "user10"},
    #     ]
    #     rdb.raw("ROLLBACK").exec().waitFor

    # test("whereNullTest"):
    #   setUp(rdb)
    #   asyncBlock:
    #     rdb.table("user").insert(%*{"email": "user11@gmail.com"}).waitFor
    #     var t = rdb
    #             .select("id", "name", "email")
    #             .table("user")
    #             .whereNull("name")
    #             .get()
    #             .waitFor
    #     echo t
    #     check t[0]["id"].getInt() == 11

    # test("groupByTest"):
    #   setUp(rdb)
    #   asyncBlock:
    #     rdb.raw("BEGIN").exec().waitFor
    #     var t = rdb
    #             .table("user")
    #             .groupBy("auth_id")
    #             .max("id")
    #             .waitFor()
    #             .get()
    #     echo t
    #     check t == "9"
    #     rdb.raw("ROLLBACK").exec().waitFor

    # test("havingTest"):
    #   asyncBlock:
    #     rdb.raw("BEGIN").exec().waitFor
    #     var t = rdb
    #             .select("id", "name")
    #             .table("user")
    #             .groupBy("auth_id")
    #             .groupBy("id")
    #             .having("auth_id", "=", 1)
    #             .get()
    #             .waitFor
    #     echo t
    #     check t[0]["id"].getInt() == 1
    #     rdb.raw("ROLLBACK").exec().waitFor

    # test("orderByTest"):
    #   asyncBlock:
    #     rdb.raw("BEGIN").exec().waitFor
    #     var t = rdb.table("user")
    #             .orderBy("auth_id", Asc)
    #             .orderBy("id", Desc)
    #             .get()
    #             .waitFor
    #     echo t
    #     check t[0]["id"].getInt() == 9
    #     rdb.raw("ROLLBACK").exec().waitFor

    # test("joinTest"):
    #   asyncBlock:
    #     rdb.raw("BEGIN").exec().waitFor
    #     var t = rdb
    #             .select("user.id", "user.name")
    #             .table("user")
    #             .join("auth", "auth.id", "=", "user.auth_id")
    #             .where("auth.id", "=", "2")
    #             .get()
    #             .waitFor
    #     echo t
    #     check t[0]["name"].getStr() == "user2"
    #     rdb.raw("ROLLBACK").exec().waitFor

    # test("leftJoinTest"):
    #   asyncBlock:
    #     rdb.raw("BEGIN").exec().waitFor
    #     rdb.table("user").insert(%*{
    #       "name": "user11"
    #     })
    #     .waitFor
    #     var t = rdb
    #             .select("user.id", "user.name", "user.auth_id")
    #             .table("user")
    #             .leftJoin("auth", "auth.id", "=", "user.auth_id")
    #             .orderBy("user.id", Desc)
    #             .get()
    #             .waitFor
    #     echo t
    #     check t[0]["name"].getStr() == "user11"
    #     check t[0]["auth_id"] == newJNull()
    #     rdb.raw("ROLLBACK").exec().waitFor

    # test("resultIsNullTest"):
    #   asyncBlock:
    #     rdb.raw("BEGIN").exec().waitFor
    #     check waitFor(rdb.table("user").find(50)).isSome == false
    #     check newSeq[JsonNode](0) == rdb.table("user").where("id", "=", 50).get().waitFor
    #     rdb.raw("ROLLBACK").exec().waitFor

    # test("deleteTest"):
    #   asyncBlock:
    #     rdb.raw("BEGIN").exec().waitFor
    #     echo rdb.table("user").get().waitFor
    #     rdb.table("user").delete(1).waitFor
    #     check  rdb.table("user").find(1).waitFor.isSome == false
    #     rdb.raw("ROLLBACK").exec().waitFor

    # test("deleteWithWhereTest"):
    #   asyncBlock:
    #     rdb.raw("BEGIN").exec().waitFor
    #     rdb.table("user").where("name", "=", "user2").delete().waitFor
    #     check rdb.table("user").find(2).waitFor.isSome == false
    #     rdb.raw("ROLLBACK").exec().waitFor

    # test("rawQueryTest"):
    #   asyncBlock:
    #     rdb.raw("BEGIN").exec().waitFor
    #     var table ="user"
    #     let sql = &"SELECT * FROM {table} WHERE id = ?"
    #     var res = rdb.raw(sql, %[1]).get().waitFor
    #     echo res
    #     check res[0]["name"].getStr == "user1"
    #     rdb.raw("ROLLBACK").exec().waitFor

    #   asyncBlock:
    #     rdb.raw("BEGIN").exec().waitFor
    #     var table ="user"
    #     let sql = &"SELECT * FROM {table} WHERE id = ?"
    #     var res = rdb.raw(sql, %[1]).getPlain().waitFor
    #     echo res
    #     check res[0][1] == "user1"
    #     rdb.raw("ROLLBACK").exec().waitFor

    #   asyncBlock:
    #     rdb.raw("BEGIN").exec().waitFor
    #     var table ="user"
    #     let sql = &"SELECT * FROM {table} WHERE id = ?"
    #     var res = rdb.raw(sql, %[1]).get().waitFor
    #     check res[0]["name"].getStr == "user1"
    #     rdb.raw("ROLLBACK").exec().waitFor

    #   asyncBlock:
    #     rdb.raw("BEGIN").exec().waitFor
    #     var table ="user"
    #     let sql = &"SELECT * FROM {table} WHERE id = ?"
    #     var res = rdb.raw(sql, %[1]).get().waitFor
    #     echo res
    #     check res[1] == "user1"
    #     rdb.raw("ROLLBACK").exec().waitFor

    #   asyncBlock:
    #     rdb.raw("BEGIN").exec().waitFor
    #     var table ="user"
    #     var sql = &"UPDATE {table} SET name = ? WHERE id = ?"
    #     rdb.raw(sql, "updated user1", %[1]).exec().waitFor
    #     sql = &"SELECT * FROM {table} WHERE id = ?"
    #     var res = rdb.raw(sql, %[1]).firstPlain().waitFor
    #     echo res
    #     check res[1] == "updated user1"
    #     rdb.raw("ROLLBACK").exec().waitFor

    # echo &"=== {rdb} {cpuTime() - start}"
