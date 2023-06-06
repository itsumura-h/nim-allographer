discard """
  cmd: "nim c -d:reset -r $file"
"""

import std/unittest
import std/asyncdispatch
import std/json
import std/options
import std/strformat
import std/strutils
import ../src/allographer/connection
import ../src/allographer/query_builder


let setupConn = dbOpen(SurrealDb, "test", "test", "user", "pass", "http://surreal", 8000, 1, 30, false, false).waitFor()
let surreal = dbOpen(SurrealDb, "test", "test", "user", "pass", "http://surreal", 8000, 10, 30, true, false).waitFor()

suite("surreal type"):
  setup:
    setupConn.table("user").delete().waitFor()

  test("SurrealId"):
    let aliceId = surreal.table("user").insertId(%*{"name": "alice"}).waitFor()
    let alice = surreal.table("user").where("name", "=", "alice").first().waitFor().get()
    check aliceId.rawId() == alice["id"].getStr()
    check aliceId.table == alice["id"].getStr().split(":")[0]
    check $aliceId == alice["id"].getStr().split(":")[1]

    let alice2 = SurrealId.new(aliceId.rawId())
    check alice2.rawId() == alice["id"].getStr()
    check alice2.table == alice["id"].getStr().split(":")[0]
    check $alice2 == alice["id"].getStr().split(":")[1]

    let alice3 = SurrealId.new(aliceId.table, $aliceId)
    check alice3.rawId() == alice["id"].getStr()
    check alice3.table == alice["id"].getStr().split(":")[0]
    check $alice3 == alice["id"].getStr().split(":")[1]


suite("surreal query"):
  setup:
    setupConn.table("auth").delete().waitFor()
    setupConn.table("user").delete().waitFor()
    
    var userData = newSeq[JsonNode]()
    var i = 0
    for auth in ["admin", "editor", "viewer"]:
      let authId = setupConn.table("auth").insertId(%*{"name": auth}).waitFor()
      for j in 1..3:
        userData.add(%*{"name": &"user{i+j}", "email": &"user{i+j}@example.com", "index":i+j, "auth":authId.rawId})
      i += 3
    setupConn.table("user").insert(userData).waitFor()

  test("connection"):
    let surreal = dbOpen(SurrealDb, "test", "test", "user", "pass", "http://surreal", 8000, 10, 30, true, false).waitFor()
    check surreal.conn.pools.len > 0

  test("raw query"):
    surreal.table("user").insert(%*{"name": "alice", "email":"alice@example.com"}).waitFor()
    let res = surreal.raw(""" SELECT * FROM `user` ORDER BY name ASC LIMIT 1""").get().waitFor()
    echo res
    check res[0]["name"].getStr() == "alice"
    check res[0]["email"].getStr() == "alice@example.com"

  test("get"):
    surreal.insert(%*{"name": "alice", "email":"alice@example.com"}).waitFor()
    let res = surreal.table("user").orderBy("name", Collate, Asc).limit(1).get().waitFor()
    echo res
    check res[0]["name"].getStr() == "alice"
    check res[0]["email"].getStr() == "alice@example.com"

  test("first"):
    surreal.insert(%*{"name": "alice", "email":"alice@example.com"}).waitFor()
    let dbRes = surreal.table("user").orderBy("name", Collate, Asc).first().waitFor()
    check dbRes.isSome()
    let res = dbRes.get()
    echo res.pretty()
    check res["name"].getStr() == "alice"
    check res["email"].getStr() == "alice@example.com"

  test("find"):
    let aliceId = surreal.insertId(%*{"name": "alice", "email":"alice@example.com"}).waitFor()
    var dbRes = surreal.table("user").find(aliceId).waitFor()
    check dbRes.isSome()
    var res = dbRes.get()
    let id = SurrealId.new(res["id"].getStr)
    dbRes = surreal.table("user").find(id).waitFor()
    res = dbRes.get()
    check res["name"].getStr() == "alice"
    check res["email"].getStr() == "alice@example.com"


  # ==================== SELECT ====================
  
  test("select"):
    let aliceId = surreal.insertId(%*{"name": "alice", "email":"alice@example.com"}).waitFor()
    let dbRes = surreal.table("user").select("name", "email").find(aliceId).waitFor()
    check dbRes.isSome()
    let res = dbRes.get()
    echo res.pretty()
    check res["name"].getStr() == "alice"
    check res["email"].getStr() == "alice@example.com"
    check res.hasKey("id") == false

  test("select where"):
    var users = newSeq[JsonNode]()
    const names = ["alice", "bob", "charlie"]
    for name in names:
      users.add(%*{"name": name, "email": &"{name}@example.com"})
    surreal.table("user").insert(users).waitFor()

    for name in names:
      var dbRes = surreal
                    .table("user")
                    .where("name", "=", name)
                    .where("email", "=", name & "@example.com")
                    .first()
                    .waitFor()
      check dbRes.isSome()
      var res = dbRes.get()
      echo res.pretty()
      check res["name"].getStr() == name
      check res["email"].getStr() == name & "@example.com"

    let dave = surreal
                .table("user")
                .where("name", "=", "dave")
                .first()
                .waitFor()
    check dave.isSome() == false

  test("select where or"):
    var users = newSeq[JsonNode]()
    for name in ["alice", "bob", "charlie"]:
      users.add(%*{"name": name, "email": &"{name}@example.com"})
    surreal.table("user").insert(users).waitFor()

    let res = surreal
                .table("user")
                .where("name", "=", "alice")
                .orWhere("name", "=", "bob")
                .get()
                .waitFor()
    echo res
    for row in res:
      if row["name"].getStr() == "alice":
        check true
        continue
      if row["name"].getStr() == "bob":
        check true
        continue
      if row["name"].getStr() == "charlie":
        check false
        break

  test("order by"):
    var res = surreal.table("user").orderBy("name", Asc).get().waitFor()
    check res[0]["name"].getStr() == "user1"

    res = surreal.table("user").orderBy("name", Desc).get().waitFor()
    check res[0]["name"].getStr() == "user9"

    res = surreal.table("user").orderBy("index", Numeric, Asc).get().waitFor()
    check res[0]["name"].getStr() == "user1"

    res = surreal.table("user").orderBy("index", Numeric, Desc).get().waitFor()
    check res[0]["name"].getStr() == "user9"

    res = surreal.table("user").orderBy("name", Collate, Asc).get().waitFor()
    check res[0]["name"].getStr() == "user1"

    res = surreal.table("user").orderBy("name", Collate, Desc).get().waitFor()
    check res[0]["name"].getStr() == "user9"

  test("limit"):
    var res = surreal.table("user").limit(1).get().waitFor()
    check res.len == 1

    res = surreal.table("user").limit(2).get().waitFor()
    check res.len == 2

  test("start"):
    var res = surreal.table("user").orderBy("index", Asc).limit(1).start(1).get().waitFor()
    check res.len == 1
    check res[0]["index"].getInt() == 2

    res = surreal.table("user").orderBy("index", Asc).limit(1).start(2).get().waitFor()
    check res.len == 1
    check res[0]["index"].getInt() == 3

  test("group by"):
    let res = surreal.table("user").select("auth.name").groupBy("auth.name").get().waitFor()
    echo res
    check res == @[%*{"auth":{"name":"admin"}}, %*{"auth":{"name":"editor"}}, %*{"auth":{"name":"viewer"}}]

  test("fetch"):
    var res = surreal.table("user").where("name", "=", "user1").fetch("auth").first().waitFor().get()
    check res["auth"]["name"].getStr() == "admin"
    res = surreal.table("user").where("name", "=", "user4").fetch("auth").first().waitFor().get()
    check res["auth"]["name"].getStr() == "editor"
    res = surreal.table("user").where("name", "=", "user7").fetch("auth").first().waitFor().get()
    check res["auth"]["name"].getStr() == "viewer"

  test("parallel"):
    setupConn.raw(""" DELETE `user` """).exec().waitFor()
    let admin = surreal.table("auth").where("name", "=", "admin").first().waitFor().get()
    let adminId = admin["id"].getStr()
    var users = newSeq[JsonNode]()
    for i in 100..<1000:
      users.add(%*{"name": &"user{i}", "email": &"user{i}@example.com", "index": i, "auth": adminId})
    surreal.table("user").insert(users).waitFor()

    let res = surreal.table("user").where("auth.name", "=", "admin").fetch("auth").parallel().get().waitFor()
    check res.len == 900


  # ==================== AGGREGATE ====================

  test("count"):
    let users = surreal.table("user").get().waitFor()
    let count = surreal.table("user").count().waitFor()
    echo count
    check users.len == count


  test("max"):
    surreal.table("data").delete().waitFor()
    var data = newSeq[JsonNode]()
    for i in 1..5:
      data.add(%*{"index": i})
    surreal.table("data").insert(data).waitFor()

    let max = surreal.table("data").max("index").waitFor()
    check max == 5

  test("min"):
    surreal.table("data").delete().waitFor()
    var data = newSeq[JsonNode]()
    for i in 1..5:
      data.add(%*{"index": i})
    surreal.table("data").insert(data).waitFor()

    let min = surreal.table("data").min("index").waitFor()
    check min == 1


  # ==================== INSERT ====================

  test("insert"):
    surreal.table("user").insert(%*{"name":"user1", "email":"user1@example.com"}).waitFor()
    let dbRes = surreal.table("user").where("name", "=", "user1").first().waitFor()
    check dbRes.isSome()
    let res = dbRes.get()
    check res["email"].getStr() == "user1@example.com"

  test("insert values"):
    surreal.table("user")
      .insert(@[
        %*{"name":"user1", "email":"user1@example.com"},
        %*{"name":"user2", "email":"user2@example.com"},
      ])
      .waitFor()
    var dbRes = surreal.table("user").where("name", "=", "user1").first().waitFor()
    check dbRes.isSome()
    var res = dbRes.get()
    check res["email"].getStr() == "user1@example.com"

    dbRes = surreal.table("user").where("name", "=", "user2").first().waitFor()
    check dbRes.isSome()
    res = dbRes.get()
    check res["email"].getStr() == "user2@example.com"

  test("insert id"):
    let id = surreal.table("user").insertId(%*{"name":"user1", "email":"user1@example.com"}).waitFor()
    check id.rawId.len > 0

  test("insert values id"):
    var users = newSeq[JsonNode]()
    for i in 1..10:
      users.add(%*{"name": &"user{i}", "email": &"user{i}@example.com"})
    let ids = surreal.table("user").insertId(users).waitFor()
    check ids.len == 10


  # ==================== UPDATE ====================

  test("update"):
    let aliceId = surreal.table("user").insertId(%*{"name": "alice", "email": "alice@example.com"}).waitFor()
    surreal.table("user").where("id", "=", aliceId.rawId).update(%*{"name": "updated"}).waitFor()
    let alice = surreal.table("user").where("email", "=", "alice@example.com").first().waitFor().get()
    echo alice
    check alice["name"].getStr() == "updated"

  test("update merge"):
    let aliceId = surreal.table("user").insertId(%*{"name": "alice", "email": "alice@example.com"}).waitFor()
    surreal.update(aliceId, %*{"name": "updated"}).waitFor()
    let alice = surreal.table("user").find(aliceId).waitFor().get()
    echo alice
    check alice["name"].getStr() == "updated"


  # ==================== DELETE ====================

  test("delete"):
    let aliceId = surreal.table("user").insertId(%*{"name": "alice", "email": "alice@example.com"}).waitFor()
    surreal.table("user").where("name", "=", "alice").delete().waitFor()
    let alice = surreal.table("user").find(aliceId).waitFor()
    check not alice.isSome
  
  test("delete by id"):
    let aliceId = surreal.table("user").insertId(%*{"name": "alice", "email": "alice@example.com"}).waitFor()
    surreal.delete(aliceId).waitFor()
    let alice = surreal.table("user").find(aliceId).waitFor()
    check not alice.isSome
