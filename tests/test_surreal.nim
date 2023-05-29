discard """
  cmd: "nim c -d:reset -r $file"
"""

import std/unittest
import std/asyncdispatch
import std/json
import std/options
import std/strformat
import ../src/allographer/connection
import ../src/allographer/query_builder

let surreal = dbOpen(SurrealDb, "test", "test", "user", "pass", "http://surreal", 8000, 10, 30, true, false).waitFor()

suite("surreal"):
  setup:
    echo "=== setup start ==="
    surreal.raw(""" DELETE `auth` """).exec().waitFor()
    surreal.raw(""" DELETE `user` """).exec().waitFor()
    let admin = surreal.raw(""" INSERT INTO `auth` (`index`, `name`) VALUES (1, "admin") """).get().waitFor()
    let adminId = admin[0]["id"].getStr()
    surreal.raw(&""" INSERT INTO `user` (`index`, `name`, `email`, `auth`) VALUES (1, "alice", "alice@example.com", "{adminId}") """).exec().waitFor()
    echo "=== setup end ==="

  test("connection"):
    let surreal = dbOpen(SurrealDb, "test", "test", "user", "pass", "http://surreal", 8000, 10, 30, true, false).waitFor()
    check surreal.conn.pools.len > 0

  test("raw query"):
    let res = surreal.raw(""" SELECT * FROM `user` LIMIT 1""").get().waitFor()
    echo res
    check res[0]["name"].getStr() == "alice"
    check res[0]["email"].getStr() == "alice@example.com"

  test("get"):
    let res = surreal.table("user").get().waitFor()
    echo res
    check res[0]["name"].getStr() == "alice"
    check res[0]["email"].getStr() == "alice@example.com"

  test("first"):
    let dbRes = surreal.table("user").first().waitFor()
    check dbRes.isSome()
    let res = dbRes.get()
    echo res.pretty()
    check res["name"].getStr() == "alice"
    check res["email"].getStr() == "alice@example.com"

  test("find"):
    var dbRes = surreal.table("user").first().waitFor()
    check dbRes.isSome()
    var res = dbRes.get()
    dbRes = surreal.table("user").find(res["id"].getStr).waitFor()
    res = dbRes.get()
    check res["name"].getStr() == "alice"
    check res["email"].getStr() == "alice@example.com"

  test("select"):
    let dbRes = surreal.table("user").select("name", "email").first().waitFor()
    check dbRes.isSome()
    let res = dbRes.get()
    echo res.pretty()
    check res["name"].getStr() == "alice"
    check res["email"].getStr() == "alice@example.com"
    check res.hasKey("id") == false

  test("select where"):
    surreal.raw("""
      INSERT INTO `user`
        (index, name, email)
      VALUES
        (2, "bob", "bob@example.com"),
        (3, "charlie", "charlie@example.com")
    """).exec().waitFor()

    for name in ["alice", "bob", "charlie"]:
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
    surreal.raw("""
      INSERT INTO `user`
        (index, name, email)
      VALUES
        (2, "bob", "bob@example.com"),
        (3, "charlie", "charlie@example.com")
    """).exec().waitFor()

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
    surreal.raw("""
      INSERT INTO `user`
        (index, name, email)
      VALUES
        (2, "bob", "bob@example.com"),
        (3, "charlie", "charlie@example.com")
    """).exec().waitFor()

    var res = surreal.table("user").orderBy("index", Asc).get().waitFor()
    check res[0]["name"].getStr() == "alice"

    res = surreal.table("user").orderBy("index", Desc).get().waitFor()
    check res[0]["name"].getStr() == "charlie"

    res = surreal.table("user").orderBy("index", Numeric, Asc).get().waitFor()
    check res[0]["name"].getStr() == "alice"

    res = surreal.table("user").orderBy("index", Numeric, Desc).get().waitFor()
    check res[0]["name"].getStr() == "charlie"

    res = surreal.table("user").orderBy("name", Collate, Asc).get().waitFor()
    check res[0]["name"].getStr() == "alice"

    res = surreal.table("user").orderBy("name", Collate, Desc).get().waitFor()
    check res[0]["name"].getStr() == "charlie"

  test("limit"):
    surreal.raw("""
      INSERT INTO `user`
        (index, name, email)
      VALUES
        (2, "bob", "bob@example.com"),
        (3, "charlie", "charlie@example.com")
    """).exec().waitFor()

    var res = surreal.table("user").limit(1).get().waitFor()
    check res.len == 1

    res = surreal.table("user").limit(2).get().waitFor()
    check res.len == 2

  test("start"):
    surreal.raw("""
      INSERT INTO `user`
        (index, name, email)
      VALUES
        (2, "bob", "bob@example.com"),
        (3, "charlie", "charlie@example.com")
    """).exec().waitFor()

    var res = surreal.table("user").orderBy("index", Asc).limit(1).start(1).get().waitFor()
    check res.len == 1
    check res[0]["index"].getInt() == 2

    res = surreal.table("user").orderBy("index", Asc).limit(1).start(2).get().waitFor()
    check res.len == 1
    check res[0]["index"].getInt() == 3

  test("group by"):
    surreal.raw("""
      INSERT INTO `auth`
        (index, name, email)
      VALUES
        (2, "editor"),
        (3, "viewer")
    """).exec().waitFor()

    let editor = surreal.table("auth").where("name", "=", "editor").first().waitFor().get()
    let editorId = editor["id"].getStr()
    let viewer = surreal.table("auth").where("name", "=", "viewer").first().waitFor().get()
    let viewerId = viewer["id"].getStr()

    for i in 2..4:
      surreal.raw(&""" INSERT INTO `user` (index, name, email, auth) VALUES ({i}, "user{i}", "user{i}@example.com", "{adminId}") """).exec().waitFor()
    for i in 5..7:
      surreal.raw(&""" INSERT INTO `user` (index, name, email, auth) VALUES ({i}, "user{i}", "user{i}@example.com", "{editorId}") """).exec().waitFor()
    for i in 8..10:
      surreal.raw(&""" INSERT INTO `user` (index, name, email, auth) VALUES ({i}, "user{i}", "user{i}@example.com", "{viewerId}") """).exec().waitFor()
    echo surreal.table("user").where("name", "=", "alice").get().waitFor()
    for row in surreal.raw("SELECT * FROM `user` ORDER BY index ASC FETCH auth").get().waitFor():
      echo row.pretty()

    let res = surreal.table("user").select("auth.name").groupBy("auth.name").get().waitFor()
    echo res
    check res == @[%*{"auth":{"name":"admin"}}, %*{"auth":{"name":"editor"}}, %*{"auth":{"name":"viewer"}}]

  test("fetch"):
    surreal.raw("""
      INSERT INTO `auth`
        (index, name, email)
      VALUES
        (2, "editor"),
        (3, "viewer")
    """).exec().waitFor()

    let editor = surreal.table("auth").where("name", "=", "editor").first().waitFor().get()
    let editorId = editor["id"].getStr()
    let viewer = surreal.table("auth").where("name", "=", "viewer").first().waitFor().get()
    let viewerId = viewer["id"].getStr()

    for i in 2..4:
      surreal.raw(&""" INSERT INTO `user` (index, name, email, auth) VALUES ({i}, "user{i}", "user{i}@example.com", "{adminId}") """).exec().waitFor()
    for i in 5..7:
      surreal.raw(&""" INSERT INTO `user` (index, name, email, auth) VALUES ({i}, "user{i}", "user{i}@example.com", "{editorId}") """).exec().waitFor()
    for i in 8..10:
      surreal.raw(&""" INSERT INTO `user` (index, name, email, auth) VALUES ({i}, "user{i}", "user{i}@example.com", "{viewerId}") """).exec().waitFor()
    
    var res = surreal.table("user").where("name", "=", "alice").orderBy("index", Asc).fetch("auth").first().waitFor().get()
    check res["auth"]["name"].getStr() == "admin"
    res = surreal.table("user").where("name", "=", "user5").orderBy("index", Asc).fetch("auth").first().waitFor().get()
    check res["auth"]["name"].getStr() == "editor"
    res = surreal.table("user").where("name", "=", "user8").orderBy("index", Asc).fetch("auth").first().waitFor().get()
    check res["auth"]["name"].getStr() == "viewer"

  test("parallel"):
    surreal.raw("""
      INSERT INTO `auth`
        (index, name, email)
      VALUES
        (2, "editor"),
        (3, "viewer")
    """).exec().waitFor()

    let editor = surreal.table("auth").where("name", "=", "editor").first().waitFor().get()
    let editorId = editor["id"].getStr()
    let viewer = surreal.table("auth").where("name", "=", "viewer").first().waitFor().get()
    let viewerId = viewer["id"].getStr()

    var query = "INSERT INTO `user` (index, name, email, auth) VALUES "
    for i in 2..200:
      if i > 2: query.add(", ")
      query.add(&"""({i}, "user{i}", "user{i}@example.com", "{adminId}")""")
    surreal.raw(query).exec().waitFor()
    
    query = "INSERT INTO `user` (index, name, email, auth) VALUES "
    for i in 201..400:
      if i > 201: query.add(", ")
      query.add(&"""({i}, "user{i}", "user{i}@example.com", "{editorId}")""")
    surreal.raw(query).exec().waitFor()

    query = "INSERT INTO `user` (index, name, email, auth) VALUES "
    for i in 401..600:
      if i > 401: query.add(", ")
      query.add(&"""({i}, "user{i}", "user{i}@example.com", "{viewerId}")""")
    surreal.raw(query).exec().waitFor()

    let res = surreal.table("user").orderBy("index", Asc).fetch("auth").parallel().get().waitFor()
    # echo res
    check res.len == 600

  test("insert value"):
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
