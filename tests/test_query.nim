discard """
  cmd: "nim c -d:reset -r $file"
"""

import
  std/unittest,
  std/json,
  std/strformat,
  std/options,
  std/asyncdispatch,
  std/random,
  std/times,
  ../src/allographer/schema_builder,
  ../src/allographer/query_builder,
  ../src/allographer/connection,
  ./connections


randomize()

proc setup(rdb:Rdb) =
  rdb.create([
    table("auth",[
      Column.increments("id"),
      Column.string("auth")
    ]),
    table("users",[
      Column.increments("id"),
      Column.string("name").nullable(),
      Column.string("email").nullable(),
      Column.string("address").nullable(),
      Column.date("submit_on").nullable(),
      Column.datetime("submit_at").nullable(),
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

  seeder rdb, "users":
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

    rdb.table("users").insert(users).waitFor

# =============================================================================
# test
# =============================================================================

for rdb in dbConnections:
  let start = cpuTime()
  block getTest:
    setup(rdb)
    asyncBlock:
      var t = rdb.table("users").get().await
      check t[0] == %*{"id":1,"name":"user1","email":"user1@gmail.com","address":newJNull(),"submit_on":"2020-01-01","submit_at":"2020-01-01 00:00:00","auth_id":1}

  block getPlainTest:
    setup(rdb)
    asyncBlock:
      var t = rdb.table("users").getPlain().await
      check t[0] == @["1", "user1", "user1@gmail.com", "", "2020-01-01", "2020-01-01 00:00:00", "1"]

  block perfomanceTest:
    setup(rdb)
    asyncBlock:
      var s = cpuTime()
      for i in 0..100:
        discard rdb.table("users").get().await
      echo "get...", cpuTime() - s
      s = cpuTime()
      for i in 0..100:
        discard rdb.table("users").getPlain().await
      echo "getPlain...", cpuTime() - s

  block firstTest:
    setup(rdb)
    asyncBlock:
      var t = await(rdb.table("users").where("name", "=", "user1").first).get
      check t == %*{"id": 1, "name": "user1", "email": "user1@gmail.com", "address":newJNull(), "submit_on":"2020-01-01","submit_at":"2020-01-01 00:00:00", "auth_id": 1}

  block firstPlainTest:
    setup(rdb)
    asyncBlock:
      var t = rdb.table("users").firstPlain().await
      check t == @["1", "user1", "user1@gmail.com", "", "2020-01-01", "2020-01-01 00:00:00", "1"]

  block findTest:
    setup(rdb)
    asyncBlock:
      var t = rdb.table("users").find(1).await.get
      check t == %*{"id": 1, "name": "user1", "email": "user1@gmail.com", "address":newJNull(), "submit_on":"2020-01-01","submit_at":"2020-01-01 00:00:00", "auth_id": 1}

  block findStringTest:
    setup(rdb)
    asyncBlock:
      var t = rdb.table("users").find("1").await.get
      check t == %*{"id": 1, "name": "user1", "email": "user1@gmail.com", "address":newJNull(), "submit_on":"2020-01-01","submit_at":"2020-01-01 00:00:00", "auth_id": 1}

  block findPlainTest:
    setup(rdb)
    asyncBlock:
      var t = rdb.table("users").findPlain(1).await
      check t == @["1", "user1", "user1@gmail.com", "", "2020-01-01", "2020-01-01 00:00:00", "1"]

  block selectTest:
    setup(rdb)
    asyncBlock:
      var t = rdb.table("users").select("name", "email").get().await
      check t[0] == %*{"name": "user1", "email": "user1@gmail.com"}

  block selectAsTest:
    setup(rdb)
    asyncBlock:
      var t = rdb.table("users").select("name as user_name", "email").get().await
      check t[0] == %*{"user_name": "user1", "email": "user1@gmail.com"}

  block selectLikeTest:
    setup(rdb)
    asyncBlock:
      var t = rdb.table("users").select("email").where("email", "LIKE", "%10%").get().await
      check t == @[%*{"email":"user10@gmail.com"}]
      t = rdb.table("users").select("email").where("email", "LIKE", "user10%").get().await
      check t == @[%*{"email":"user10@gmail.com"}]
      t = rdb.table("users").select("email").where("email", "LIKE", "%10@gmail.com%").get().await
      check t == @[%*{"email":"user10@gmail.com"}]

  block whereTest:
    setup(rdb)
    asyncBlock:
      var t = rdb.table("users").where("auth_id", "=", "1").get().await
      check t == @[
        %*{"id":1,"name":"user1","email":"user1@gmail.com","address":newJNull(),"submit_on":"2020-01-01","submit_at":"2020-01-01 00:00:00","auth_id":1},
        %*{"id":3,"name":"user3","email":"user3@gmail.com","address":newJNull(),"submit_on":"2020-03-01","submit_at":"2020-03-01 00:00:00","auth_id":1},
        %*{"id":5,"name":"user5","email":"user5@gmail.com","address":newJNull(),"submit_on":"2020-05-01","submit_at":"2020-05-01 00:00:00","auth_id":1},
        %*{"id":7,"name":"user7","email":"user7@gmail.com","address":newJNull(),"submit_on":"2020-07-01","submit_at":"2020-07-01 00:00:00","auth_id":1},
        %*{"id":9,"name":"user9","email":"user9@gmail.com","address":newJNull(),"submit_on":"2020-09-01","submit_at":"2020-09-01 00:00:00","auth_id":1}
      ]

  block orWhereTest:
    setup(rdb)
    asyncBlock:
      var t = rdb.table("users").where("auth_id", "=", "1").orWhere("name", "=", "user2").get().await
      check t == @[
        %*{"id":1,"name":"user1","email":"user1@gmail.com","address":newJNull(),"submit_on":"2020-01-01","submit_at":"2020-01-01 00:00:00","auth_id":1},
        %*{"id":2,"name":"user2","email":"user2@gmail.com","address":newJNull(),"submit_on":"2020-02-01","submit_at":"2020-02-01 00:00:00","auth_id":2},
        %*{"id":3,"name":"user3","email":"user3@gmail.com","address":newJNull(),"submit_on":"2020-03-01","submit_at":"2020-03-01 00:00:00","auth_id":1},
        %*{"id":5,"name":"user5","email":"user5@gmail.com","address":newJNull(),"submit_on":"2020-05-01","submit_at":"2020-05-01 00:00:00","auth_id":1},
        %*{"id":7,"name":"user7","email":"user7@gmail.com","address":newJNull(),"submit_on":"2020-07-01","submit_at":"2020-07-01 00:00:00","auth_id":1},
        %*{"id":9,"name":"user9","email":"user9@gmail.com","address":newJNull(),"submit_on":"2020-09-01","submit_at":"2020-09-01 00:00:00","auth_id":1}
      ]

  block updateTest:
    setup(rdb)
    asyncBlock:
      rdb.table("users").where("id", "=", 2).update(%*{"name": "John"}).await
      var t = await(rdb.table("users").find(2)).get
      check t["name"].getStr() == "John"

  block insertIdTest:
    setup(rdb)
    asyncBlock:
      var id = rdb.table("users").insertId(%*{"name": "John"}).await
      var t = rdb.table("users").find(id).await.get
      check t["name"].getStr() == "John"

  block insertsIDTest:
    setup(rdb)
    asyncBlock:
      var ids = rdb.table("users").insertsID(@[
        %*{"name": "John"},
        %*{"email": "Paul@gmail.com"},
      ])
      .await
      var t = await(rdb.table("users").find(ids[0])).get
      check t["name"].getStr() == "John"
      t = await(rdb.table("users").find(ids[1])).get
      check t["email"].getStr() == "Paul@gmail.com"

  block insertnilTest:
    setup(rdb)
    asyncBlock:
      var id = rdb.table("users").insertId(%*{
        "name": "John",
        "email": newJNull(),
        "address": ""
      })
      .await
      var res = rdb.table("users").find(id).await
      echo res.get
      check res.get["email"] == newJNull()

      res = rdb.table("users").where("email", "is", nil).first().await
      echo res.get
      check res.get["email"] == newJNull()

  block distinctTest:
    setup(rdb)
    asyncBlock:
      var t = rdb.table("users").select("id", "name").distinct()
      check t.query.hasKey("distinct") == true

  block whereBetweenTest:
    setup(rdb)
    asyncBlock:
      var t = rdb
              .table("users")
              .select("id", "name")
              .where("auth_id", "=", 1)
              .whereBetween("id", [6, 9])
              .get()
              .await
      echo t
      check t[0]["name"].getStr() == "user7"

  block whereBetweenStringTest:
    setup(rdb)
    asyncBlock:
      var t = rdb
              .table("users")
              .whereBetween("submit_at", ["2020-01-01 00:00:00", "2020-01-31 00:00:00"])
              .get()
              .await
      check t[0]["name"].getStr == "user1"

      t = rdb
          .table("users")
          .whereBetween("submit_on", ["2020-01-01", "2020-01-31"])
          .get()
          .await
      check t[0]["name"].getStr == "user1"

  block whereNotBetweenTest:
    setup(rdb)
    asyncBlock:
      var t = rdb
              .table("users")
              .select("id", "name")
              .where("auth_id", "=", 1)
              .whereNotBetween("id", [1, 4])
              .get()
              .await
      check t[0]["name"].getStr() == "user5"

  block whereNotBetweenStringTest:
    setup(rdb)
    asyncBlock:
      var t = rdb
              .table("users")
              .whereNotBetween("submit_at", ["2020-2-1 00:00:00", "2020-12-31 00:00:00"])
              .get()
              .await
      check t[0]["name"].getStr == "user1"

      t = rdb
          .table("users")
          .whereNotBetween("submit_on", ["2020-2-1", "2020-12-31"])
          .get()
          .await
      check t[0]["name"].getStr == "user1"

  block whereInTest:
    setup(rdb)
    asyncBlock:
      var t = rdb
              .table("users")
              .select("id", "name")
              .whereBetween("id", [4, 10])
              .whereIn("id", @[5, 6, 7])
              .get()
              .await
      echo t
      check t[0]["name"].getStr() == "user5"

  block whereNotInTest:
    setup(rdb)
    asyncBlock:
      var t = rdb
              .table("users")
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

  block whereNullTest:
    setup(rdb)
    asyncBlock:
      rdb.table("users").insert(%*{"email": "user11@gmail.com"}).await
      var t = rdb
              .table("users")
              .select("id", "name", "email")
              .whereNull("name")
              .get()
              .await
      echo t
      check t[0]["id"].getInt() == 11

  block groupByTest:
    setup(rdb)
    asyncBlock:
      var t = rdb
              .table("users")
              .select("max(id)")
              .groupBy("auth_id")
              .get()
              .await
      echo t
      if rdb.driver == SQLite3:
        check t[0]["max(id)"].getStr() == "9"
      if rdb.driver == MySQL:
        check t[0]["max(id)"].getInt() == 9
      if rdb.driver == PostgreSQL:
        check t[0]["max"].getInt() == 9

  block havingTest:
    setup(rdb)
    asyncBlock:
      var t = rdb
              .table("users")
              .select("id", "name")
              .groupBy("auth_id")
              .groupBy("id")
              .having("auth_id", "=", 1)
              .get()
              .await
      echo t
      check t[0]["id"].getInt() == 1

  block orderByTest:
    setup(rdb)
    asyncBlock:
      var t = rdb.table("users")
              .orderBy("auth_id", Asc)
              .orderBy("id", Desc)
              .get()
              .await
      echo t
      check t[0]["id"].getInt() == 9

  block joinTest:
    setup(rdb)
    asyncBlock:
      var t = rdb.table("users")
              .select("users.id", "users.name")
              .join("auth", "auth.id", "=", "users.auth_id")
              .where("auth.id", "=", "2")
              .get()
              .await
      echo t
      check t[0]["name"].getStr() == "user2"

  block leftJoinTest:
    setup(rdb)
    asyncBlock:
      rdb.table("users").insert(%*{
        "name": "user11"
      })
      .await
      var t = rdb.table("users")
              .select("users.id", "users.name", "users.auth_id")
              .leftJoin("auth", "auth.id", "=", "users.auth_id")
              .orderBy("users.id", Desc)
              .get()
              .await
      echo t
      check t[0]["name"].getStr() == "user11"
      check t[0]["auth_id"] == newJNull()

  block resultIsNullTest:
    setup(rdb)
    asyncBlock:
      check await(rdb.table("users").find(50)).isSome == false
      check newSeq[JsonNode](0) == rdb.table("users").where("id", "=", 50).get().await

  block deleteTest:
    setup(rdb)
    asyncBlock:
      echo rdb.table("users").get().await
      rdb.table("users").delete(1).await
      check  await(rdb.table("users").find(1)).isSome == false

  block deleteWithWhereTest:
    setup(rdb)
    asyncBlock:
      rdb.table("users").where("name", "=", "user2").delete().await
      check await(rdb.table("users").find(2)).isSome == false

  block rawQueryTest:
    setup(rdb)
    asyncBlock:
      let sql = "SELECT * FROM users WHERE id = ?"
      var res = rdb.raw(sql, "1").getRaw().await
      echo res
      check res[0]["name"].getStr == "user1"

  echo &"=== {rdb.driver} {cpuTime() - start}"
