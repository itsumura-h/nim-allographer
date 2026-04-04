# nim c -r --threads:off -d:reset example/sqlite/benchmark.nim

import std/asyncdispatch
import std/json
import std/os
import std/random
import std/strutils
import std/monotimes
import std/times
import ../../src/allographer/connection
import ../../src/allographer/query_builder
import ../../src/allographer/schema_builder


randomize()

const
  range1_10000 = 1..10000
  countNum = 500
  shouldDisplayLog = false
  selectSql = "SELECT index as id, randomNumber FROM World WHERE index = ?"
  updateSql = "UPDATE World SET randomNumber = ? WHERE index = ?"


let
  maxConnections = getEnv("DB_MAX_CONNECTION", "95").parseInt
  timeout = getEnv("DB_TIMEOUT", "30").parseInt

  sqlitePath = getEnv("SQLITE_PATH", "db.sqlite3")


proc timeProcess(name: string, cb: proc(): Future[void]) {.async.} =
  var eachTime = 0.0
  var sumTime = 0.0
  const repeatCount = 5
  var resultStr = ""

  for i in 1..repeatCount:
    sleep(100)
    let start = getMonoTime()
    await cb()
    eachTime = float64((getMonoTime() - start).inMilliseconds) / 1000.0
    sumTime += eachTime
    if i > 1: resultStr.add("\n")
    resultStr.add("|" & $i & "|" & $eachTime & "|")

  echo name
  echo "|num|time|"
  echo "|---|---|"
  echo resultStr
  echo "|Avg|" & $(sumTime / repeatCount) & "|"
  echo ""


proc sqliteBenchmarkScenario(rdb: SqliteConnections) {.async.} =
  rdb.create(
    table("World", [
      Column.increments("index"),
      Column.integer("randomNumber").default(0)
    ])
  )
  seeder(rdb, "World"):
    var data = newSeq[JsonNode]()
    for i in range1_10000:
      data.add(
        %*{"randomNumber": rand(range1_10000)}
      )
    await rdb.table("World").insert(data)

  proc benchUpdate() {.async.} =
    var futures = newSeq[Future[void]](countNum)
    for i in 1..countNum:
      let index = rand(range1_10000)
      let number = rand(range1_10000)
      futures[i - 1] = (proc(): Future[void] {.async.} =
        discard rdb.select("index as id", "randomNumber").table("World").where("index", "=", index).first().await
        rdb.table("World").where("index", "=", index).update(%*{"randomNumber": number}).await
      )()
    await all(futures)
  
  proc benchUpdatePreparedCold() {.async.} =
    let selectStmt = rdb.prepare(selectSql)
    let updateStmt = rdb.prepare(updateSql)
    defer:
      selectStmt.close().await
      updateStmt.close().await
    var futures = newSeq[Future[void]](countNum)
    for i in 1..countNum:
      let index = rand(range1_10000)
      let number = rand(range1_10000)
      futures[i - 1] = (proc(): Future[void] {.async.} =
        rdb.withConn(
          proc(ctx: SqlitePreparedContext): Future[void] {.async.} =
            discard await selectStmt.first(ctx, @[$index])
            await updateStmt.exec(ctx, @[$number, $index])
        )
      )()
    await all(futures)

  let selectStmtWarm = rdb.prepare(selectSql)
  let updateStmtWarm = rdb.prepare(updateSql)

  proc benchUpdatePreparedWarm() {.async.} =
    var futures = newSeq[Future[void]](countNum)
    for i in 1..countNum:
      let index = rand(range1_10000)
      let number = rand(range1_10000)
      futures[i - 1] = (proc(): Future[void] {.async.} =
        rdb.withConn(
          proc(ctx: SqlitePreparedContext): Future[void] {.async.} =
            discard await selectStmtWarm.first(ctx, @[$index])
            await updateStmtWarm.exec(ctx, @[$number, $index])
        )
      )()
    await all(futures)

  await timeProcess("sqlite benchmark", benchUpdate)
  await timeProcess("sqlite benchmark prepared cold", benchUpdatePreparedCold)
  await timeProcess("sqlite benchmark prepared warm", benchUpdatePreparedWarm)


proc main() =
  let rdb = dbOpen(SQLite3, sqlitePath, maxConnections, timeout, shouldDisplayLog=shouldDisplayLog)
  sqliteBenchmarkScenario(rdb).waitFor

main()
