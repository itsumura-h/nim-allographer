discard """
  cmd: "nim c -d:reset -d:ssl -r $file"
"""

import std/unittest
import std/asyncdispatch
import std/httpclient
import std/json
import std/options
import std/streams
import std/strformat
import ../../../src/allographer/schema_builder
import ../../../src/allographer/query_builder
import ./connection


proc setup(rdb:MariadbConnections) =
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
          "email": &"user{i}@example.com",
          "auth_id": authId,
          "submit_on": &"2020-{month}-01",
          "submit_at": &"2020-{month}-01 00:00:00",
        }
      )

    rdb.table("user").insert(users).waitFor

let rdb = mariadb


setup(rdb)

suite($rdb & " get"):
  test("get"):
    let t = rdb.table("user").get().waitFor
    let expect = %*{"id":1,"name":"user1","email":"user1@example.com","address":newJNull(),"submit_on":"2020-01-01","submit_at":"2020-01-01 00:00:00","auth_id":1}
    echo t[0]
    echo expect
    check t[0] == expect


  test("getPlain"):
    let t = rdb.table("user").getPlain().waitFor
    check t[0] == @["1", "user1", "user1@example.com", "", "2020-01-01", "2020-01-01 00:00:00", "1"]


  test("first"):
    var t = rdb.table("user").where("name", "=", "user1").first().waitFor().get
    check t == %*{"id": 1, "name": "user1", "email": "user1@example.com", "address":newJNull(), "submit_on":"2020-01-01","submit_at":"2020-01-01 00:00:00", "auth_id": 1}


  test("firstPlain"):
    var t = rdb.table("user").firstPlain().waitFor
    check t == @["1", "user1", "user1@example.com", "", "2020-01-01", "2020-01-01 00:00:00", "1"]


  test("find"):
    var t = rdb.table("user").find(1).waitFor.get
    check t == %*{"id": 1, "name": "user1", "email": "user1@example.com", "address":newJNull(), "submit_on":"2020-01-01","submit_at":"2020-01-01 00:00:00", "auth_id": 1}


  test("findString"):
    var t = rdb.table("user").find("1").waitFor.get
    check t == %*{"id": 1, "name": "user1", "email": "user1@example.com", "address":newJNull(), "submit_on":"2020-01-01","submit_at":"2020-01-01 00:00:00", "auth_id": 1}


  test("findPlain"):
    var t = rdb.table("user").findPlain(1).waitFor
    check t == @["1", "user1", "user1@example.com", "", "2020-01-01", "2020-01-01 00:00:00", "1"]


  test("columns"):
    let columns = rdb.table("user").columns().waitFor
    check columns == @["id", "name", "email", "address", "submit_on", "submit_at", "auth_id"]


  test("select"):
    var t = rdb.select("name", "email").table("user").get().waitFor
    check t[0] == %*{"name": "user1", "email": "user1@example.com"}


  test("selectAs"):
    var t = rdb.select("name as user_name", "email").table("user").get().waitFor
    check t[0] == %*{"user_name": "user1", "email": "user1@example.com"}


  test("selectLike"):
    var t = rdb.select("email").table("user").where("email", "LIKE", "%10%").get().waitFor
    check t == @[%*{"email":"user10@example.com"}]
    t = rdb.select("email").table("user").where("email", "LIKE", "user10%").get().waitFor
    check t == @[%*{"email":"user10@example.com"}]
    t = rdb.select("email").table("user").where("email", "LIKE", "%10@example.com%").get().waitFor
    check t == @[%*{"email":"user10@example.com"}]


  test("where"):
    var t = rdb.table("user").where("auth_id", "=", "1").get().waitFor
    check t == @[
      %*{"id":1,"name":"user1","email":"user1@example.com","address":newJNull(),"submit_on":"2020-01-01","submit_at":"2020-01-01 00:00:00","auth_id":1},
      %*{"id":3,"name":"user3","email":"user3@example.com","address":newJNull(),"submit_on":"2020-03-01","submit_at":"2020-03-01 00:00:00","auth_id":1},
      %*{"id":5,"name":"user5","email":"user5@example.com","address":newJNull(),"submit_on":"2020-05-01","submit_at":"2020-05-01 00:00:00","auth_id":1},
      %*{"id":7,"name":"user7","email":"user7@example.com","address":newJNull(),"submit_on":"2020-07-01","submit_at":"2020-07-01 00:00:00","auth_id":1},
      %*{"id":9,"name":"user9","email":"user9@example.com","address":newJNull(),"submit_on":"2020-09-01","submit_at":"2020-09-01 00:00:00","auth_id":1}
    ]


  test("orWhere"):
    var t = rdb.table("user").where("auth_id", "=", "1").orWhere("name", "=", "user2").get().waitFor
    check t == @[
      %*{"id":1,"name":"user1","email":"user1@example.com","address":newJNull(),"submit_on":"2020-01-01","submit_at":"2020-01-01 00:00:00","auth_id":1},
      %*{"id":2,"name":"user2","email":"user2@example.com","address":newJNull(),"submit_on":"2020-02-01","submit_at":"2020-02-01 00:00:00","auth_id":2},
      %*{"id":3,"name":"user3","email":"user3@example.com","address":newJNull(),"submit_on":"2020-03-01","submit_at":"2020-03-01 00:00:00","auth_id":1},
      %*{"id":5,"name":"user5","email":"user5@example.com","address":newJNull(),"submit_on":"2020-05-01","submit_at":"2020-05-01 00:00:00","auth_id":1},
      %*{"id":7,"name":"user7","email":"user7@example.com","address":newJNull(),"submit_on":"2020-07-01","submit_at":"2020-07-01 00:00:00","auth_id":1},
      %*{"id":9,"name":"user9","email":"user9@example.com","address":newJNull(),"submit_on":"2020-09-01","submit_at":"2020-09-01 00:00:00","auth_id":1}
    ]


  test("whereBetween"):
    var t = rdb
            .select("id", "name")
            .table("user")
            .where("auth_id", "=", 1)
            .whereBetween("id", [6, 9])
            .get()
            .waitFor
    echo t
    check t[0]["name"].getStr() == "user7"


  test("whereBetweenString"):
    var t = rdb
            .table("user")
            .whereBetween("submit_at", ["2020-01-01 00:00:00", "2020-01-31 00:00:00"])
            .get()
            .waitFor
    check t[0]["name"].getStr == "user1"

    t = rdb
        .table("user")
        .whereBetween("submit_on", ["2020-01-01", "2020-01-31"])
        .get()
        .waitFor
    check t[0]["name"].getStr == "user1"


  test("whereNotBetween"):
    var t = rdb
            .select("id", "name")
            .table("user")
            .where("auth_id", "=", 1)
            .whereNotBetween("id", [1, 4])
            .get()
            .waitFor
    check t[0]["name"].getStr() == "user5"


  test("whereNotBetweenString"):
    var t = rdb
            .table("user")
            .whereNotBetween("submit_at", ["2020-2-1 00:00:00", "2020-12-31 00:00:00"])
            .get()
            .waitFor
    check t[0]["name"].getStr == "user1"

    t = rdb
        .table("user")
        .whereNotBetween("submit_on", ["2020-2-1", "2020-12-31"])
        .get()
        .waitFor
    check t[0]["name"].getStr == "user1"


  test("whereIn"):
    var t = rdb
            .select("id", "name")
            .table("user")
            .whereBetween("id", [4, 10])
            .whereIn("id", @[5, 6, 7])
            .get()
            .waitFor
    echo t
    check t[0]["name"].getStr() == "user5"
    
    t = rdb
        .select("id", "name")
        .table("user")
        .whereBetween("id", [4, 10])
        .whereIn("name", @["user5", "user6", "user7"])
        .get()
        .waitFor
    check t[0]["name"].getStr() == "user5"


  test("whereNotIn"):
    var t = rdb
            .select("id", "name")
            .table("user")
            .whereBetween("id", [4, 10])
            .whereNotIn("id", @[5, 6, 7])
            .get()
            .waitFor
    echo t
    check t == @[
      %*{"id":4, "name": "user4"},
      %*{"id":8, "name": "user8"},
      %*{"id":9, "name": "user9"},
      %*{"id":10, "name": "user10"},
    ]
    
    t = rdb
        .select("id", "name")
        .table("user")
        .whereBetween("id", [4, 10])
        .whereNotIn("name", @["user5", "user6", "user7"])
        .get()
        .waitFor
    echo t
    check t == @[
      %*{"id":4, "name": "user4"},
      %*{"id":8, "name": "user8"},
      %*{"id":9, "name": "user9"},
      %*{"id":10, "name": "user10"},
    ]


  test("whereNull"):
    setUp(rdb)
    rdb.table("user").insert(%*{"email": "user11@example.com"}).waitFor
    var t = rdb
            .select("id", "name", "email")
            .table("user")
            .whereNull("name")
            .get()
            .waitFor
    echo t
    check t[0]["id"].getInt() == 11


  test("groupBy"):
    var t = rdb
            .table("user")
            .groupBy("auth_id")
            .max("id")
            .waitFor()
            .get()
    echo t
    check t == "11"


  test("having"):
    var t = rdb
            .select("id", "name")
            .table("user")
            .groupBy("auth_id")
            .groupBy("id")
            .having("auth_id", "=", 1)
            .get()
            .waitFor
    echo t
    check t[0]["id"].getInt() == 1


  test("orderBy"):
    var t = rdb.table("user")
            .where("auth_id", "is not", nil)
            .orderBy("auth_id", Asc)
            .orderBy("id", Desc)
            .get()
            .waitFor
    echo t
    check t[0]["id"].getInt() == 9


  test("join"):
    var t = rdb
            .select("user.id", "user.name")
            .table("user")
            .join("auth", "auth.id", "=", "user.auth_id")
            .where("auth.id", "=", "2")
            .get()
            .waitFor
    echo t
    check t[0]["name"].getStr() == "user2"


  test("leftJoin"):
    rdb.table("user").insert(%*{
      "name": "user11"
    })
    .waitFor
    var t = rdb
            .select("user.id", "user.name", "user.auth_id")
            .table("user")
            .leftJoin("auth", "auth.id", "=", "user.auth_id")
            .orderBy("user.id", Desc)
            .get()
            .waitFor
    echo t
    check t[0]["name"].getStr() == "user11"
    check t[0]["auth_id"] == newJNull()


  test("resultIsNull"):
    check rdb.table("user").find(50).waitFor().isSome == false
    check newSeq[JsonNode](0) == rdb.table("user").where("id", "=", 50).get().waitFor


suite($rdb & " insert"):
  setup:
    setup(rdb)

  test("insert row"):
    rdb.table("user").insert(%*{"name": "Alice"}).waitFor
    let t = rdb.table("user").orderBy("id", Desc).first().waitFor().get()
    check t["name"].getStr() == "Alice"


  test("insert rows"):
    rdb.table("user").insert(@[
      %*{"name": "Alice"},
      %*{"name": "Bob"},
    ]).waitFor
    let t = rdb.table("user").orderBy("id", Desc).limit(2).get().waitFor()
    check t[0]["name"].getStr() == "Bob"
    check t[1]["name"].getStr() == "Alice"


  test("insertId row"):
    var id = rdb.table("user").insertId(%*{"name": "Alice"}).waitFor
    echo id
    let t = rdb.table("user").find(id).waitFor().get()
    check t["name"].getStr() == "Alice"

  
  test("insertId rows"):
    let ids = rdb.table("user").insertId(@[
      %*{"name": "Alice"},
      %*{"name": "Bob"},
    ]).waitFor
    
    var t = rdb.table("user").find(ids[0]).waitFor().get()
    check t["name"].getStr == "Alice"

    t = rdb.table("user").find(ids[1]).waitFor().get()
    check t["name"].getStr == "Bob"


  test("insertNil"):
    var id = rdb.table("user").insertId(%*{
      "name": "Alice",
      "email": nil,
      "address": ""
    })
    .waitFor
    var res = rdb.table("user").find(id).waitFor
    echo res.get
    check res.get["email"] == newJNull()

    res = rdb.table("user").where("email", "is", nil).first().waitFor
    echo res.get
    check res.get["email"] == newJNull()


suite($rdb & " update"):
  setup:
    setup(rdb)

  test("update"):
    rdb.table("user").where("id", "=", 1).update(%*{"name": "Alice"}).waitFor
    var t = rdb.table("user").find(1).waitFor().get()
    check t["name"].getStr() == "Alice"


suite($rdb & " delete"):
  setup(rdb)

  test("delete"):
    rdb.table("user").delete(1).waitFor
    check rdb.table("user").find(1).waitFor.isSome == false


  test("delete where"):
    rdb.table("user").where("name", "=", "user1").delete().waitFor
    check rdb.table("user").find(1).waitFor.isSome == false


suite($rdb & " rawQuery"):
  setup(rdb)

  test("get"):
    echo rdb.table("user").get().waitFor
    let sql = &"SELECT * FROM `user` WHERE `id` = ?"
    let res = rdb.raw(sql, %*[1]).get().waitFor
    echo res
    check res[0]["name"].getStr == "user1"


  test("getPlain"):
    let sql = &"SELECT * FROM `user` WHERE `id` = ?"
    let res = rdb.raw(sql, %*[1]).getPlain().waitFor
    echo res
    check res[0][1] == "user1"


  test("first"):
    echo rdb.table("user").get().waitFor
    let sql = &"SELECT * FROM `user` WHERE `id` = ?"
    let res = rdb.raw(sql, %*[1]).first().waitFor().get()
    echo res
    check res["name"].getStr == "user1"


  test("firstPlain"):
    echo rdb.table("user").get().waitFor
    let sql = &"SELECT name FROM `user` WHERE `id` = ?"
    let res = rdb.raw(sql, %*[1]).firstPlain().waitFor()
    echo res
    check res[0] == "user1"


  test("exec"):
    var sql = "UPDATE `user` SET `name` = ? WHERE `id` = ?"
    rdb.raw(sql, %*["updated user1", 1]).exec().waitFor
    sql = &"SELECT * FROM `user` WHERE `id` = ?"
    let res = rdb.raw(sql, %[1]).get().waitFor
    echo res
    check res[0]["name"].getStr == "updated user1"


setup(rdb)
suite($rdb & " aggregates"):
  test("count"):
    var t = rdb.table("user").count().waitFor
    check t == 10

  test("max"):
    var t = rdb.table("user").max("name").waitFor.get
    check t == "user9"
    var t2 = rdb.table("user").max("id").waitFor.get
    check t2 == "10"

  test("min"):
    var t = rdb.table("user").min("name").waitFor.get
    check t == "user1"
    var t2 = rdb.table("user").min("id").waitFor.get
    check t2 == "1"

  test("avg"):
    var t = rdb.table("user").avg("id").waitFor.get
    check t == 5.5

  test("sum"):
    var t = rdb.table("user").sum("id").waitFor.get
    check t == 55.0


suite($rdb & " insert binary"):
  test("should success"):
    rdb.create(
      table("test", [
        Column.increments("id"),
        Column.binary("pic"),
      ])
    )

    let client = newAsyncHttpClient()
    let response = client.getContent("https://nim-lang.org/assets/img/twitter_banner.png").waitFor()
    let imageStream = newStringStream(response)
    let binaryImage = imageStream.readAll()

    let id = rdb.table("test").insertId(%*{"pic": binaryImage}).waitFor()

    var res = rdb.table("test").find(id).waitFor().get()
    check res["pic"].getStr().len > 0

    rdb.table("test").where("id","=", id).update(%*{"pic": binaryImage}).waitFor()

    res = rdb.table("test").find(id).waitFor().get()
    check res["pic"].getStr().len > 0

rdb.raw("DROP TABLE IF EXISTS `test`").exec().waitFor()
rdb.raw("DROP TABLE IF EXISTS `user`").exec().waitFor()
rdb.raw("DROP TABLE IF EXISTS `auth`").exec().waitFor()
