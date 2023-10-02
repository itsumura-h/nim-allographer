discard """
  cmd: "nim c -d:reset -r $file"
"""

import std/unittest
import std/asyncdispatch
import std/json
import std/options
import std/strformat
import std/times
import ../../../src/allographer/schema_builder
import ../../../src/allographer/query_builder
import ./connection
import ./clear_tables


# =============================================================================
# test
# =============================================================================

proc setup(rdb:SurrealConnections) =
  # rdb.raw("REMOVE TABLE auth; REMOVE TABLE user").exec().waitFor
  # rdb.raw("DEFINE TABLE auth SCHEMAFULL; DEFINE TABLE user SCHEMAFULL").exec().waitFor
  rdb.create([
    table("auth",[
      Column.increments("index"),
      Column.string("name")
    ]),
    table("user",[
      Column.increments("index"),
      Column.string("name").nullable(),
      Column.string("email").nullable(),
      Column.string("address").nullable(),
      Column.date("submit_on"),
      Column.datetime("submit_at"),
      Column.foreign("auth").reference("id").on("auth").onDelete(SET_NULL).nullable()
    ])
  ])

  # seeder
  var adminId, userId:SurrealId
  seeder(rdb, "auth"):
    adminId = rdb.table("auth").insertId(%*{"name":"admin"}).waitFor()
    userId = rdb.table("auth").insertId(%*{"name":"user"}).waitFor()

  seeder(rdb, "user"):
    var users: seq[JsonNode]
    for i in 1..10:
      let authId = if i mod 2 == 0: userId else: adminId
      let month = if i > 9: $i else: &"0{i}"
      users.add(
        %*{
          "name": &"user{i}",
          "email": &"user{i}@example.com",
          "auth": authId,
          "submit_on": &"2020-{month}-01",
          "submit_at": &"2020-{month}-01 00:00:00",
        }
      )

    rdb.table("user").insert(users).waitFor()


let rdb = surreal

setup(rdb)

suite($rdb & " get"):
  test("get"):
    let t = rdb.table("user").orderBy("name", Asc).get().waitFor()
    echo t[0]
    check t[0]["index"].getInt() == 1
    check t[0]["name"].getStr() == "user1"
    check t[0]["email"].getStr() == "user1@example.com"
    check t[0]["address"].kind == JNull
    check t[0]["submit_on"].getStr().parse("yyyy-MM-dd'T'hh:mm:ss'Z'").format("yyyy-MM-dd") == "2020-01-01"
    check t[0]["submit_at"].getStr() == "2020-01-01T00:00:00Z"


  test("first"):
    var t = rdb.table("user").where("name", "=", "user1").orderBy("name", Asc).first().waitFor().get()
    check t["index"].getInt() == 1
    check t["name"].getStr() == "user1"
    check t["email"].getStr() == "user1@example.com"
    check t["address"].kind == JNull
    check t["submit_on"].getStr().parse("yyyy-MM-dd'T'hh:mm:ss'Z'").format("yyyy-MM-dd") == "2020-01-01"
    check t["submit_at"].getStr() == "2020-01-01T00:00:00Z"


  test("find"):
    var t = rdb.table("user").where("name", "=", "user1").orderBy("name", Asc).first().waitFor().get()
    let id = SurrealId.new(t["id"].getStr())
    t = rdb.table("user").find(id).waitFor().get()
    check t["index"].getInt() == 1
    check t["name"].getStr() == "user1"
    check t["email"].getStr() == "user1@example.com"
    check t["address"].kind == JNull
    check t["submit_on"].getStr().parse("yyyy-MM-dd'T'hh:mm:ss'Z'").format("yyyy-MM-dd") == "2020-01-01"
    check t["submit_at"].getStr() == "2020-01-01T00:00:00Z"


  test("columns"):
    let columns = rdb.table("user").columns().waitFor()
    check columns == @["address", "auth", "email", "index", "name", "submit_at", "submit_on"]


  test("select"):
    var t = rdb.select("name", "email").table("user").orderBy("name", Asc).get().waitFor()
    check t[0] == %*{"name": "user1", "email": "user1@example.com"}


  test("selectAs"):
    var t = rdb.select("name as user_name", "email").table("user").orderBy("user_name", Asc).get().waitFor()
    check t[0] == %*{"user_name": "user1", "email": "user1@example.com"}


  test("selectLike"):
    let users = rdb.table("user").where("email", "CONTAINS", "10").get().waitFor()
    check users[0]["email"].getStr() == "user10@example.com"
    
    var user10 = rdb.raw("SELECT * FROM user WHERE string::startsWith(email, \"user10\")").first().waitFor()
    check user10.get()["email"].getStr() == "user10@example.com"

    user10 = rdb.raw("SELECT * FROM user WHERE string::endsWith(email, \"10@example.com\")").first().waitFor()
    check user10.get()["email"].getStr() == "user10@example.com"


  test("where string"):
    let admin = rdb.table("auth").where("name", "=", "admin").first().waitFor().get()
    let adminId = SurrealId.new(admin["id"].getStr())

    var t = rdb.table("user").where("auth", "=", adminId.rawId()).orderBy("index", Asc).get().waitFor()
    const ids = [1,3,5,7,9]
    for i, row in t:
      check row["index"].getInt() == ids[i]
      check row["name"].getStr() == &"user{ids[i]}" 
      check row["email"].getStr() == &"user{ids[i]}@example.com" 
      check row["address"].kind == JNull
      check row["submit_on"].getStr() == &"2020-0{ids[i]}-01T00:00:00Z"


  test("where int"):
    var t = rdb.table("user").where("index", "=", 1).orderBy("index", Asc).first().waitFor().get()
    check t["index"].getInt() == 1
    check t["name"].getStr() == "user1" 
    check t["email"].getStr() == "user1@example.com" 
    check t["address"].kind == JNull
    check t["submit_on"].getStr() == "2020-01-01T00:00:00Z"


  test("orWhere"):
    let admin = rdb.table("auth").where("name", "=", "admin").first().waitFor().get()
    let adminId = SurrealId.new(admin["id"].getStr())

    var t = rdb.table("user").where("auth", "=", adminId).orWhere("name", "=", "user2").orderBy("index", Asc).get().waitFor()
    const ids = [1,2,3,5,7,9]
    for i, row in t:
      check row["index"].getInt() == ids[i]
      check row["name"].getStr() == &"user{ids[i]}" 
      check row["email"].getStr() == &"user{ids[i]}@example.com" 
      check row["address"].kind == JNull
      check row["submit_on"].getStr() == &"2020-0{ids[i]}-01T00:00:00Z"


  test("whereBetween"):
    var t = rdb
            .table("user")
            .whereBetween("index", [6, 9])
            .orderBy("index", Asc)
            .get()
            .waitFor()

    const ids = [6,7,8,9]
    for i, row in t:
      check row["index"].getInt() == ids[i]
      check row["name"].getStr() == &"user{ids[i]}" 
      check row["email"].getStr() == &"user{ids[i]}@example.com" 
      check row["address"].kind == JNull
      check row["submit_on"].getStr() == &"2020-0{ids[i]}-01T00:00:00Z"


  test("whereNotBetween"):
    var t = rdb
            .table("user")
            .whereNotBetween("index", [2, 6])
            .orderBy("index", Asc)
            .get()
            .waitFor()

    const ids = [1,7,8,9]
    for i, row in t:
      check row["index"].getInt() == ids[i]
      check row["name"].getStr() == &"user{ids[i]}" 
      check row["email"].getStr() == &"user{ids[i]}@example.com" 
      check row["address"].kind == JNull
      check row["submit_on"].getStr() == &"2020-0{ids[i]}-01T00:00:00Z"


  test("whereIn"):
    var t = rdb
            .table("user")
            .whereIn("index", @[5, 6, 7])
            .orderBy("index", Asc)
            .get()
            .waitFor()

    const ids = [5,6,7]
    for i, row in t:
      check row["index"].getInt() == ids[i]
      check row["name"].getStr() == &"user{ids[i]}" 
      check row["email"].getStr() == &"user{ids[i]}@example.com" 
      check row["address"].kind == JNull
      check row["submit_on"].getStr() == &"2020-0{ids[i]}-01T00:00:00Z"


  test("whereNotIn"):
    var t = rdb
            .table("user")
            .whereNotIn("index", @[4, 5, 6, 7, 10])
            .orderBy("index", Asc)
            .get()
            .waitFor()

    const ids = [1,2,3,8,9]
    for i, row in t:
      check row["index"].getInt() == ids[i]
      check row["name"].getStr() == &"user{ids[i]}" 
      check row["email"].getStr() == &"user{ids[i]}@example.com" 
      check row["address"].kind == JNull
      check row["submit_on"].getStr() == &"2020-0{ids[i]}-01T00:00:00Z"


  test("whereNull"):
    rdb.table("user").insert(%*{"email": "user11@example.com"}).waitFor()
    var t = rdb
            .table("user")
            .whereNull("name")
            .first()
            .waitFor()
    check t.get()["index"].getInt() == 11

  setUp(rdb)

  # TODO: not work
  # test("groupBy"):
  #   var t = rdb
  #           .select("auth.name")
  #           .table("user")
  #           .groupBy("auth.name")
  #           .get()
  #           .waitFor()
  #   echo t


  test("orderBy"):
    var res = rdb.table("user").orderBy("name", Asc).get().waitFor()
    check res[0]["name"].getStr() == "user1"

    res = rdb.table("user").orderBy("name", Desc).get().waitFor()
    check res[0]["name"].getStr() == "user9"

    res = rdb.table("user").orderBy("index", Numeric, Asc).get().waitFor()
    check res[0]["name"].getStr() == "user1"

    res = rdb.table("user").orderBy("index", Numeric, Desc).get().waitFor()
    check res[0]["name"].getStr() == "user10"

    res = rdb.table("user").orderBy("name", Collate, Asc).get().waitFor()
    check res[0]["name"].getStr() == "user1"

    res = rdb.table("user").orderBy("name", Collate, Desc).get().waitFor()
    check res[0]["name"].getStr() == "user9"


  test("fetch"):
    var res = rdb.table("user").where("name", "=", "user1").fetch("auth").first().waitFor().get()
    check res["auth"]["name"].getStr() == "admin"
    res = rdb.table("user").where("name", "=", "user2").fetch("auth").first().waitFor().get()
    check res["auth"]["name"].getStr() == "user"


  test("resultIsNull"):
    check rdb.table("user").where("id", "=", 50).first().waitFor().isSome() == false
    check newSeq[JsonNode](0) == rdb.table("user").where("id", "=", 50).get().waitFor()


suite($rdb & " insert"):
  setup:
    setup(rdb)

  test("insert row"):
    rdb.table("user").insert(%*{"name": "Alice"}).waitFor
    let t = rdb.table("user").orderBy("index", Desc).first().waitFor().get()
    check t["name"].getStr() == "Alice"


  test("insert rows"):
    rdb.table("user").insert(@[
      %*{"name": "Alice"},
      %*{"name": "Bob"},
    ]).waitFor
    let t = rdb.table("user").orderBy("index", Desc).limit(2).get().waitFor()
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
    check res.get["email"] == newJNull()

    res = rdb.table("user").where("email", "is", nil).first().waitFor
    check res.get["email"] == newJNull()


suite($rdb & " update"):
  setup:
    setup(rdb)


  test("update"):
    var user1 = rdb.table("user").where("index", "=", 1).first().waitFor().get()
    let user1Id = SurrealId.new(user1["id"].getStr())
    rdb.table("user").where("id", "=", user1Id).update(%*{"name": "Alice"}).waitFor()
    user1 = rdb.table("user").find(user1Id).waitFor().get()
    check user1["name"].getStr() == "Alice"


  test("update merge"):
    var user1 = rdb.table("user").where("index", "=", 1).first().waitFor().get()
    let user1Id = SurrealId.new(user1["id"].getStr())
    rdb.update(user1Id, %*{"name": "updated"}).waitFor()
    user1 = rdb.table("user").find(user1Id).waitFor().get()
    check user1["name"].getStr() == "updated"


suite($rdb & " delete"):
  setup:
    setup(rdb)

  test("delete"):
    let user1 = rdb.table("user").where("index", "=", 1).first().waitFor().get()
    let user1Id = SurrealId.new(user1["id"].getStr())
    rdb.table("user").where("name", "=", "user1").delete().waitFor()
    check rdb.table("user").find(user1Id).waitFor().isSome() == false

  test("delete id"):
    let user1 = rdb.table("user").where("index", "=", 1).first().waitFor().get()
    let user1Id = SurrealId.new(user1["id"].getStr())
    rdb.table("user").delete(user1Id).waitFor
    check rdb.table("user").find(user1Id).waitFor().isSome() == false


suite($rdb & " rawQuery"):
  setup(rdb)

  test("get"):
    let sql = &"SELECT * FROM `user` WHERE `index` = ?"
    let res = rdb.raw(sql, %*[1]).get().waitFor
    check res[0]["name"].getStr == "user1"


  test("first"):
    let sql = &"SELECT * FROM `user` WHERE `index` = ?"
    let res = rdb.raw(sql, %*[1]).first().waitFor().get()
    check res["name"].getStr() == "user1"


  test("exec"):
    var sql = "SELECT * FROM `user` WHERE `index` = ?"
    let user1 = rdb.raw(sql, %*[1]).first().waitFor().get()
    let user1Id = SurrealId.new(user1["id"].getStr())

    sql = "UPDATE `user` SET `name` = ? WHERE `id` = ?"
    rdb.raw(sql, %*["updated", user1Id.rawId()]).exec().waitFor
    
    sql = &"SELECT * FROM `user` WHERE `id` = ?"
    let res = rdb.raw(sql, %[user1Id.rawId()]).get().waitFor
    check res[0]["name"].getStr == "updated"


setup(rdb)
suite($rdb & " aggregates"):

  test("count"):
    var t = rdb.table("user").count().waitFor()
    check t == 10

  test("max"):
    var t = rdb.table("user").max("name", Collate).waitFor()
    check t == "user9"
    var t2 = rdb.table("user").max("index", Numeric).waitFor()
    check t2 == "10"

  test("min"):
    var t = rdb.table("user").min("name", Collate).waitFor()
    check t == "user1"
    var t2 = rdb.table("user").min("index", Numeric).waitFor()
    check t2 == "1"

  test("avg"):
    let t = rdb.table("user").avg("index").waitFor()
    check t == 5.5
  
  test("sum"):
    let t = rdb.table("user").sum("index").waitFor()
    check t == 55.0


clearTables(rdb).waitFor()
