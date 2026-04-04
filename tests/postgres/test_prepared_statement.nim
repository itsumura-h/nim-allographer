discard """
  cmd: "nim c -d:reset -d:ssl -r $file"
"""

import std/unittest
import std/asyncdispatch
import std/json
import std/options
import std/strformat
import ../../src/allographer/schema_builder
import ../../src/allographer/query_builder
import ./connections


let rdb = postgres


proc setup(rdb: PostgresConnections) =
  rdb.create([
    table("auth", [
      Column.increments("id"),
      Column.string("auth")
    ]),
    table("user", [
      Column.increments("id"),
      Column.string("name").nullable(),
      Column.string("email").nullable(),
      Column.string("address").nullable(),
      Column.date("submit_on").nullable(),
      Column.datetime("submit_at").nullable(),
      Column.foreign("auth_id").reference("id").onTable("auth").onDelete(SET_NULL).nullable()
    ])
  ])

  seeder(rdb, "auth"):
    rdb.table("auth").insert(@[
      %*{"auth": "admin"},
      %*{"auth": "user"}
    ]).waitFor

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


setup(rdb)


suite($rdb & " prepared statement"):
  test("aged connection refresh"):
    rdb.pools.maxConnectionLifetime = 1
    rdb.pools.maxConnectionIdleTime = 1
    for conn in rdb.pools.conns.mitems:
      conn.createdAt = 0
      conn.lastUsedAt = 0

    let sql = """SELECT "id", "name", "email", "address" FROM "user" WHERE "id" = ?"""
    let stmt = rdb.prepare(sql)
    defer:
      waitFor stmt.close()

    let rowOpt = stmt.first(@["1"]).waitFor
    check rowOpt.isSome

    var refreshed = false
    for conn in rdb.pools.conns:
      if conn.createdAt > 0:
        refreshed = true
        break
    check refreshed

  test("select"):
    let stmt = rdb.prepare("""SELECT "id", "name", "email", "address" FROM "user" WHERE "id" = ?""")
    defer:
      waitFor stmt.close()

    let args = newJArray()
    args.add(newJInt(1))

    let rows = stmt.get(args).waitFor
    check rows.len == 1
    check rows[0] == %*{"id": 1, "name": "user1", "email": "user1@example.com", "address": newJNull()}
    let rowOpt = stmt.first(args).waitFor
    let row = options.get(rowOpt)
    check row["name"].getStr == "user1"
    check stmt.getPlain(args).waitFor[0][1] == "user1"
    check stmt.firstPlain(args).waitFor[1] == "user1"


  test("logical close and clear cache"):
    let sql = """SELECT "id", "name", "email", "address" FROM "user" WHERE "id" = ?"""
    let stmt = rdb.prepare(sql)
    discard waitFor stmt.first(@["1"])
    waitFor stmt.close()

    let stmt2 = rdb.prepare(sql)
    defer:
      waitFor stmt2.close()

    let rowOpt = stmt2.first(@["1"]).waitFor
    check rowOpt.isSome

    waitFor rdb.clearStmtCache()
    let stmt3 = rdb.prepare(sql)
    defer:
      waitFor stmt3.close()
    check stmt3.first(@["1"]).waitFor.isSome


  test("with prepared connection context"):
    let selectStmt = rdb.prepare("""SELECT "id", "name" FROM "user" WHERE "id" = ?""")
    let updateStmt = rdb.prepare("""UPDATE "user" SET "address" = ? WHERE "id" = ?""")
    defer:
      waitFor selectStmt.close()
      waitFor updateStmt.close()

    waitFor rdb.withConn(
      proc(ctx: PostgresPreparedContext): Future[void] {.async.} =
        discard await selectStmt.first(ctx, @["1"])
        await updateStmt.exec(ctx, @["ctx-address", "1"])
    )

    let rowOpt = rdb.table("user").find(1).waitFor
    let row = options.get(rowOpt)
    check row["address"].getStr == "ctx-address"


  test("update null"):
    let stmt = rdb.prepare("""UPDATE "user" SET "address" = ? WHERE "id" = ?""")
    defer:
      waitFor stmt.close()

    waitFor stmt.exec(@["NULL", "1"])
    let rowOpt = rdb.table("user").find(1).waitFor
    let row = options.get(rowOpt)
    check row["address"].kind == JNull
