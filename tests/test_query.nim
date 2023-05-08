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
import ../src/allographer/utils
import ./connections


randomize()

proc setUp(rdb:Rdb) =
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
  seeder rdb, "auth":
    rdb.table("auth").insert(@[
      %*{"auth": "admin"},
      %*{"auth": "user"}
    ])
    .waitFor

  seeder rdb, "user":
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

# =============================================================================
# test
# =============================================================================

for rdb in dbConnections:
  setUp(rdb)
  
  suite("test query"):
    let start = cpuTime()

    test("getTest"):
      asyncBlock:
        rdb.raw("BEGIN").exec().await
        var t = rdb.table("user").get().await
        check t[0] == %*{"id":1,"name":"user1","email":"user1@gmail.com","address":newJNull(),"submit_on":"2020-01-01","submit_at":"2020-01-01 00:00:00","auth_id":1}
        rdb.raw("ROLLBACK").exec().await

    test("getPlainTest"):
      asyncBlock:
        rdb.raw("BEGIN").exec().await
        var t = rdb.table("user").getPlain().await
        check t[0] == @["1", "user1", "user1@gmail.com", "", "2020-01-01", "2020-01-01 00:00:00", "1"]
        rdb.raw("ROLLBACK").exec().await

    test("perfomanceTest"):
      asyncBlock:
        rdb.raw("BEGIN").exec().await
        var s = cpuTime()
        for i in 0..100:
          discard rdb.table("user").get().await
        echo "get...", cpuTime() - s
        s = cpuTime()
        for i in 0..100:
          discard rdb.table("user").getPlain().await
        echo "getPlain...", cpuTime() - s      
        rdb.raw("ROLLBACK").exec().await

    test("firstTest"):
      asyncBlock:
        rdb.raw("BEGIN").exec().await
        var t = await(rdb.table("user").where("name", "=", "user1").first).get
        check t == %*{"id": 1, "name": "user1", "email": "user1@gmail.com", "address":newJNull(), "submit_on":"2020-01-01","submit_at":"2020-01-01 00:00:00", "auth_id": 1}
        rdb.raw("ROLLBACK").exec().await

    test("firstPlainTest"):
      asyncBlock:
        rdb.raw("BEGIN").exec().await
        var t = rdb.table("user").firstPlain().await
        check t == @["1", "user1", "user1@gmail.com", "", "2020-01-01", "2020-01-01 00:00:00", "1"]
        rdb.raw("ROLLBACK").exec().await
      
    test("findTest"):
      asyncBlock:
        rdb.raw("BEGIN").exec().await
        var t = rdb.table("user").find(1).await.get
        check t == %*{"id": 1, "name": "user1", "email": "user1@gmail.com", "address":newJNull(), "submit_on":"2020-01-01","submit_at":"2020-01-01 00:00:00", "auth_id": 1}
        rdb.raw("ROLLBACK").exec().await

    test("findStringTest"):
      asyncBlock:
        rdb.raw("BEGIN").exec().await
        var t = rdb.table("user").find("1").await.get
        check t == %*{"id": 1, "name": "user1", "email": "user1@gmail.com", "address":newJNull(), "submit_on":"2020-01-01","submit_at":"2020-01-01 00:00:00", "auth_id": 1}
        rdb.raw("ROLLBACK").exec().await

    test("findPlainTest"):
      asyncBlock:
        rdb.raw("BEGIN").exec().await
        var t = rdb.table("user").findPlain(1).await
        check t == @["1", "user1", "user1@gmail.com", "", "2020-01-01", "2020-01-01 00:00:00", "1"]
        rdb.raw("ROLLBACK").exec().await

    test("selectTest"):
      asyncBlock:
        rdb.raw("BEGIN").exec().await
        var t = rdb.table("user").select("name", "email").get().await
        check t[0] == %*{"name": "user1", "email": "user1@gmail.com"}
        rdb.raw("ROLLBACK").exec().await

    test("selectAsTest"):
      asyncBlock:
        rdb.raw("BEGIN").exec().await
        var t = rdb.table("user").select("name as user_name", "email").get().await
        check t[0] == %*{"user_name": "user1", "email": "user1@gmail.com"}
        rdb.raw("ROLLBACK").exec().await

    test("selectLikeTest"):
      asyncBlock:
        rdb.raw("BEGIN").exec().await
        var t = rdb.table("user").select("email").where("email", "LIKE", "%10%").get().await
        check t == @[%*{"email":"user10@gmail.com"}]
        t = rdb.table("user").select("email").where("email", "LIKE", "user10%").get().await
        check t == @[%*{"email":"user10@gmail.com"}]
        t = rdb.table("user").select("email").where("email", "LIKE", "%10@gmail.com%").get().await
        check t == @[%*{"email":"user10@gmail.com"}]
        rdb.raw("ROLLBACK").exec().await

    test("whereTest"):
      asyncBlock:
        rdb.raw("BEGIN").exec().await
        var t = rdb.table("user").where("auth_id", "=", "1").get().await
        check t == @[
          %*{"id":1,"name":"user1","email":"user1@gmail.com","address":newJNull(),"submit_on":"2020-01-01","submit_at":"2020-01-01 00:00:00","auth_id":1},
          %*{"id":3,"name":"user3","email":"user3@gmail.com","address":newJNull(),"submit_on":"2020-03-01","submit_at":"2020-03-01 00:00:00","auth_id":1},
          %*{"id":5,"name":"user5","email":"user5@gmail.com","address":newJNull(),"submit_on":"2020-05-01","submit_at":"2020-05-01 00:00:00","auth_id":1},
          %*{"id":7,"name":"user7","email":"user7@gmail.com","address":newJNull(),"submit_on":"2020-07-01","submit_at":"2020-07-01 00:00:00","auth_id":1},
          %*{"id":9,"name":"user9","email":"user9@gmail.com","address":newJNull(),"submit_on":"2020-09-01","submit_at":"2020-09-01 00:00:00","auth_id":1}
        ]
        rdb.raw("ROLLBACK").exec().await

    test("orWhereTest"):
      asyncBlock:
        rdb.raw("BEGIN").exec().await
        var t = rdb.table("user").where("auth_id", "=", "1").orWhere("name", "=", "user2").get().await
        check t == @[
          %*{"id":1,"name":"user1","email":"user1@gmail.com","address":newJNull(),"submit_on":"2020-01-01","submit_at":"2020-01-01 00:00:00","auth_id":1},
          %*{"id":2,"name":"user2","email":"user2@gmail.com","address":newJNull(),"submit_on":"2020-02-01","submit_at":"2020-02-01 00:00:00","auth_id":2},
          %*{"id":3,"name":"user3","email":"user3@gmail.com","address":newJNull(),"submit_on":"2020-03-01","submit_at":"2020-03-01 00:00:00","auth_id":1},
          %*{"id":5,"name":"user5","email":"user5@gmail.com","address":newJNull(),"submit_on":"2020-05-01","submit_at":"2020-05-01 00:00:00","auth_id":1},
          %*{"id":7,"name":"user7","email":"user7@gmail.com","address":newJNull(),"submit_on":"2020-07-01","submit_at":"2020-07-01 00:00:00","auth_id":1},
          %*{"id":9,"name":"user9","email":"user9@gmail.com","address":newJNull(),"submit_on":"2020-09-01","submit_at":"2020-09-01 00:00:00","auth_id":1}
        ]
        rdb.raw("ROLLBACK").exec().await

    test("updateTest"):
      asyncBlock:
        rdb.raw("BEGIN").exec().await
        rdb.table("user").where("id", "=", 2).update(%*{"name": "John"}).await
        var t = rdb.table("user").find(2).await().get()
        check t["name"].getStr() == "John"
        rdb.raw("ROLLBACK").exec().await

    test("insertIdTest"):
      # setUp(rdb)
      asyncBlock:
        rdb.raw("BEGIN").exec().await
        var id = rdb.table("user").insertId(%*{"name": "John"}).await
        echo id
        let t = rdb.table("user").find(id).await().get()
        check t["name"].getStr() == "John"
        rdb.raw("ROLLBACK").exec().await

    test("insertsIDTest"):
      asyncBlock:
        rdb.raw("BEGIN").exec().await
        echo rdb.table("user").orderBy("id", Desc).first().await
        var ids = rdb.table("user").insertsID(@[
          %*{"name": "John"},
          %*{"email": "Paul@gmail.com"},
        ])
        .await
        var t = rdb.table("user").find(ids[0]).await.get
        check t["name"].getStr() == "John"
        t = await(rdb.table("user").find(ids[1])).get
        check t["email"].getStr() == "Paul@gmail.com"
        rdb.raw("ROLLBACK").exec().await

    test("insertnilTest"):
      asyncBlock:
        rdb.raw("BEGIN").exec().await
        var id = rdb.table("user").insertId(%*{
          "name": "John",
          "email": newJNull(),
          "address": ""
        })
        .await
        var res = rdb.table("user").find(id).await
        echo res.get
        check res.get["email"] == newJNull()

        res = rdb.table("user").where("email", "is", nil).first().await
        echo res.get
        check res.get["email"] == newJNull()
        rdb.raw("ROLLBACK").exec().await

    test("distinctTest"):
      asyncBlock:
        rdb.raw("BEGIN").exec().await
        var t = rdb.table("user").select("id", "name").distinct()
        check t.query.hasKey("distinct") == true
        rdb.raw("ROLLBACK").exec().await

    test("whereBetweenTest"):
      asyncBlock:
        rdb.raw("BEGIN").exec().await
        var t = rdb
                .table("user")
                .select("id", "name")
                .where("auth_id", "=", 1)
                .whereBetween("id", [6, 9])
                .get()
                .await
        echo t
        check t[0]["name"].getStr() == "user7"
        rdb.raw("ROLLBACK").exec().await

    test("whereBetweenStringTest"):
      asyncBlock:
        rdb.raw("BEGIN").exec().await
        var t = rdb
                .table("user")
                .whereBetween("submit_at", ["2020-01-01 00:00:00", "2020-01-31 00:00:00"])
                .get()
                .await
        check t[0]["name"].getStr == "user1"

        t = rdb
            .table("user")
            .whereBetween("submit_on", ["2020-01-01", "2020-01-31"])
            .get()
            .await
        check t[0]["name"].getStr == "user1"
        rdb.raw("ROLLBACK").exec().await

    test("whereNotBetweenTest"):
      asyncBlock:
        rdb.raw("BEGIN").exec().await
        var t = rdb
                .table("user")
                .select("id", "name")
                .where("auth_id", "=", 1)
                .whereNotBetween("id", [1, 4])
                .get()
                .await
        check t[0]["name"].getStr() == "user5"
        rdb.raw("ROLLBACK").exec().await

    test("whereNotBetweenStringTest"):
      asyncBlock:
        rdb.raw("BEGIN").exec().await
        var t = rdb
                .table("user")
                .whereNotBetween("submit_at", ["2020-2-1 00:00:00", "2020-12-31 00:00:00"])
                .get()
                .await
        check t[0]["name"].getStr == "user1"

        t = rdb
            .table("user")
            .whereNotBetween("submit_on", ["2020-2-1", "2020-12-31"])
            .get()
            .await
        check t[0]["name"].getStr == "user1"
        rdb.raw("ROLLBACK").exec().await

    test("whereInTest"):
      asyncBlock:
        rdb.raw("BEGIN").exec().await
        var t = rdb
                .table("user")
                .select("id", "name")
                .whereBetween("id", [4, 10])
                .whereIn("id", @[5, 6, 7])
                .get()
                .await
        echo t
        check t[0]["name"].getStr() == "user5"
        
        t = rdb
                .table("user")
                .select("id", "name")
                .whereBetween("id", [4, 10])
                .whereIn("name", @["user5", "user6", "user7"])
                .get()
                .await
        check t[0]["name"].getStr() == "user5"
        rdb.raw("ROLLBACK").exec().await

    test("whereNotInTest"):
      asyncBlock:
        rdb.raw("BEGIN").exec().await
        var t = rdb
                .table("user")
                .select("id", "name")
                .whereBetween("id", [4, 10])
                .whereNotIn("id", @[5, 6, 7])
                .get()
                .await
        echo t
        check t == @[
          %*{"id":4, "name": "user4"},
          %*{"id":8, "name": "user8"},
          %*{"id":9, "name": "user9"},
          %*{"id":10, "name": "user10"},
        ]
        
        t = rdb
                .table("user")
                .select("id", "name")
                .whereBetween("id", [4, 10])
                .whereNotIn("name", @["user5", "user6", "user7"])
                .get()
                .await
        echo t
        check t == @[
          %*{"id":4, "name": "user4"},
          %*{"id":8, "name": "user8"},
          %*{"id":9, "name": "user9"},
          %*{"id":10, "name": "user10"},
        ]
        rdb.raw("ROLLBACK").exec().await

    test("whereNullTest"):
      setUp(rdb)
      asyncBlock:
        rdb.table("user").insert(%*{"email": "user11@gmail.com"}).await
        var t = rdb
                .table("user")
                .select("id", "name", "email")
                .whereNull("name")
                .get()
                .await
        echo t
        check t[0]["id"].getInt() == 11

    test("groupByTest"):
      setUp(rdb)
      asyncBlock:
        rdb.raw("BEGIN").exec().await
        var t = rdb
                .table("user")
                .groupBy("auth_id")
                .max("id")
                .await()
                .get()
        echo t
        check t == "9"
        rdb.raw("ROLLBACK").exec().await

    test("havingTest"):
      asyncBlock:
        rdb.raw("BEGIN").exec().await
        var t = rdb
                .table("user")
                .select("id", "name")
                .groupBy("auth_id")
                .groupBy("id")
                .having("auth_id", "=", 1)
                .get()
                .await
        echo t
        check t[0]["id"].getInt() == 1
        rdb.raw("ROLLBACK").exec().await

    test("orderByTest"):
      asyncBlock:
        rdb.raw("BEGIN").exec().await
        var t = rdb.table("user")
                .orderBy("auth_id", Asc)
                .orderBy("id", Desc)
                .get()
                .await
        echo t
        check t[0]["id"].getInt() == 9
        rdb.raw("ROLLBACK").exec().await

    test("joinTest"):
      asyncBlock:
        rdb.raw("BEGIN").exec().await
        var t = rdb.table("user")
                .select("user.id", "user.name")
                .join("auth", "auth.id", "=", "user.auth_id")
                .where("auth.id", "=", "2")
                .get()
                .await
        echo t
        check t[0]["name"].getStr() == "user2"
        rdb.raw("ROLLBACK").exec().await

    test("leftJoinTest"):
      asyncBlock:
        rdb.raw("BEGIN").exec().await
        rdb.table("user").insert(%*{
          "name": "user11"
        })
        .await
        var t = rdb.table("user")
                .select("user.id", "user.name", "user.auth_id")
                .leftJoin("auth", "auth.id", "=", "user.auth_id")
                .orderBy("user.id", Desc)
                .get()
                .await
        echo t
        check t[0]["name"].getStr() == "user11"
        check t[0]["auth_id"] == newJNull()
        rdb.raw("ROLLBACK").exec().await

    test("resultIsNullTest"):
      asyncBlock:
        rdb.raw("BEGIN").exec().await
        check await(rdb.table("user").find(50)).isSome == false
        check newSeq[JsonNode](0) == rdb.table("user").where("id", "=", 50).get().await
        rdb.raw("ROLLBACK").exec().await

    test("deleteTest"):
      asyncBlock:
        rdb.raw("BEGIN").exec().await
        echo rdb.table("user").get().await
        rdb.table("user").delete(1).await
        check  rdb.table("user").find(1).await.isSome == false
        rdb.raw("ROLLBACK").exec().await

    test("deleteWithWhereTest"):
      asyncBlock:
        rdb.raw("BEGIN").exec().await
        rdb.table("user").where("name", "=", "user2").delete().await
        check rdb.table("user").find(2).await.isSome == false
        rdb.raw("ROLLBACK").exec().await

    test("rawQueryTest"):
      asyncBlock:
        rdb.raw("BEGIN").exec().await
        var table ="user"
        quote(table, rdb.driver)
        let sql = &"SELECT * FROM {table} WHERE id = ?"
        var res = rdb.raw(sql, "1").get().await
        echo res
        check res[0]["name"].getStr == "user1"
        rdb.raw("ROLLBACK").exec().await

      asyncBlock:
        rdb.raw("BEGIN").exec().await
        var table ="user"
        quote(table, rdb.driver)
        let sql = &"SELECT * FROM {table} WHERE id = ?"
        var res = rdb.raw(sql, "1").getPlain().await
        echo res
        check res[0][1] == "user1"
        rdb.raw("ROLLBACK").exec().await

      asyncBlock:
        rdb.raw("BEGIN").exec().await
        var table ="user"
        quote(table, rdb.driver)
        let sql = &"SELECT * FROM {table} WHERE id = ?"
        var res = rdb.raw(sql, "1").first().await
        echo res.get()
        check res.get()["name"].getStr == "user1"
        rdb.raw("ROLLBACK").exec().await

      asyncBlock:
        rdb.raw("BEGIN").exec().await
        var table ="user"
        quote(table, rdb.driver)
        let sql = &"SELECT * FROM {table} WHERE id = ?"
        var res = rdb.raw(sql, "1").firstPlain().await
        echo res
        check res[1] == "user1"
        rdb.raw("ROLLBACK").exec().await

      asyncBlock:
        rdb.raw("BEGIN").exec().await
        var table ="user"
        quote(table, rdb.driver)
        var sql = &"UPDATE {table} SET name = ? WHERE id = ?"
        rdb.raw(sql, "updated user1", "1").exec().await
        sql = &"SELECT * FROM {table} WHERE id = ?"
        var res = rdb.raw(sql, "1").firstPlain().await
        echo res
        check res[1] == "updated user1"
        rdb.raw("ROLLBACK").exec().await

    echo &"=== {rdb.driver} {cpuTime() - start}"
