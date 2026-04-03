discard """
  cmd: "nim c -d:reset $file"
"""

import std/asyncdispatch
import std/deques
import std/json
import std/tables
import std/unittest
import ../../src/allographer/query_builder/libs/surreal/surreal_lib
import ../../src/allographer/query_builder/libs/surreal/surreal_rdb
import ../../src/allographer/query_builder/log
import ../../src/allographer/query_builder/models/surreal/surreal_exec
import ../../src/allographer/query_builder/models/surreal/surreal_types


proc newTestSurreal(): SurrealConnections =
  let pools = Connections(
    conns: @[
      Connection(
        conn: SurrealConn(),
        isBusy: false,
        createdAt: 0,
      )
    ],
    timeout: 30,
    waiters: initDeque[Future[void]](),
    preparedCache: initTable[string, SurrealPreparedEntry](),
  )
  result = SurrealConnections(
    log: LogSetting(
      shouldDisplayLog: false,
      shouldOutputLogFile: false,
      logDir: "",
    ),
    pools: pools,
  )


suite "SurrealDB prepared statement":
  test "dbFormatPrepared":
    var args = newJArray()
    args.add(%*"user:alice")
    args.add(%*"2026-04-03T00:00:00Z")
    args.add(newJNull())
    let sql = dbFormatPrepared(
      questionToDaller("""SELECT * FROM "user" WHERE "id" = ? AND "submit_at" >= ? AND "address" IS ?"""),
      args
    )
    check sql ==
      """LET $a = user:alice; LET $b = <datetime>"2026-04-03T00:00:00Z"; LET $c = NONE; SELECT * FROM "user" WHERE "id" = $a AND "submit_at" >= $b AND "address" IS $c"""


  test "prepare cache lifecycle":
    let rdb = newTestSurreal()
    let sql = """SELECT * FROM "user" WHERE "id" = ?"""

    let stmt1 = rdb.prepare(sql)
    check stmt1.nArgs == 1
    check stmt1.entry.normalizedSql == questionToDaller(sql)
    check stmt1.entry.refCount == 1
    check rdb.pools.preparedCache.len == 1

    let stmt2 = rdb.prepare(sql)
    check stmt2.entry == stmt1.entry
    check stmt1.entry.refCount == 2

    waitFor stmt1.close()
    check stmt1.isClosed
    check stmt1.entry.refCount == 1

    waitFor stmt2.close()
    check stmt2.isClosed
    check stmt2.entry.refCount == 0

    let stmt4 = rdb.prepare(sql)
    check rdb.pools.preparedCache.len == 1
    waitFor rdb.flushStmt(stmt4)
    check stmt4.isClosed
    check rdb.pools.preparedCache.len == 0

    let stmt3 = rdb.prepare(sql)
    check stmt3.entry != stmt1.entry
    waitFor stmt3.close()
    waitFor rdb.clearStmtCache()
    check rdb.pools.preparedCache.len == 0


  test "withConn context":
    let rdb = newTestSurreal()

    waitFor rdb.withConn(
      proc(ctx: SurrealPreparedContext): Future[void] {.async.} =
        check ctx.owner == rdb
        check ctx.connI == 0
    )

    check not rdb.pools.conns[0].isBusy
