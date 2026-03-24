# nim c -r --threads:off benchmark.nim

import std/asyncdispatch
import std/json
import std/os
import std/random
import std/strutils
import std/monotimes
import std/times
import ../src/allographer/env
import ../src/allographer/connection
import ../src/allographer/query_builder
import ../src/allographer/schema_builder


randomize()

const
  range1_10000 = 1..10000
  countNum = 500
  shouldDisplayLog = false


let
  maxConnections = getEnv("DB_MAX_CONNECTION", "95").parseInt
  timeout = getEnv("DB_TIMEOUT", "30").parseInt

  sqlitePath = getEnv("SQLITE_PATH", "db.sqlite3")

  database = getEnv("DB_DATABASE", "database")
  user = getEnv("DB_USER", "user")
  password = getEnv("DB_PASSWORD", "pass")
  mariaHost = getEnv("MARIA_HOST", "mariadb")
  mariaPort = getEnv("MY_PORT", "3306").parseInt
  pgHost = getEnv("PG_HOST", "postgres")
  pgPort = getEnv("PG_PORT", "5432").parseInt

  surrealNamespace = getEnv("SURREAL_NS", "test")
  surrealDatabase = getEnv("SURREAL_DB", "test")
  surrealUser = getEnv("SURREAL_USER", "user")
  surrealPassword = getEnv("SURREAL_PASSWORD", "pass")
  surrealHost = getEnv("SURREAL_HOST", "http://surreal")
  surrealPort = getEnv("SURREAL_PORT", "8000").parseInt


template benchmarkScenario(rdb: untyped): untyped =
  proc migrate() {.async.} =
    rdb.create(
      table("World", [
        Column.increments("index"),
        Column.integer("randomNumber").default(0)
      ]),
      table("Fortune", [
        Column.increments("index"),
        Column.string("message")
      ])
    )

    seeder(rdb, "World"):
      var data = newSeq[JsonNode]()
      for i in range1_10000:
        data.add(
          %*{"randomNumber": rand(range1_10000)}
        )
      await rdb.table("World").insert(data)

  proc benchUpdate(): Future[seq[JsonNode]] {.async.} =
    var response = newSeq[JsonNode](countNum)
    var futures = newSeq[Future[void]](countNum)
    for i in 1..countNum:
      let index = rand(range1_10000)
      let number = rand(range1_10000)
      futures[i - 1] = (proc(): Future[void] {.async.} =
        discard rdb.select("index as id", "randomNumber").table("World").where("index", "=", index).first().await
        rdb.table("World").where("index", "=", index).update(%*{"randomNumber": number}).await
      )()
      response[i - 1] = %*{"id": index, "randomNumber": number}
    await all(futures)
    return response

  proc timeProcess[T](name: system.string, cb: proc(): Future[T]) {.async.} =
    var eachTime = 0.0
    var sumTime = 0.0
    const repeatCount = 5
    var resultStr = ""

    for i in 1..repeatCount:
      sleep(100)
      let start = getMonoTime()
      discard cb().await
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

  migrate().waitFor
  waitFor timeProcess("update", benchUpdate)


when isExistsSqlite:
  proc runSqlite() =
    echo "=== sqlite"
    let rdb = dbOpen(SQLite3, sqlitePath, maxConnections, timeout, shouldDisplayLog=shouldDisplayLog)
    benchmarkScenario(rdb)

when isExistsMariadb:
  proc runMariadb() =
    echo "=== mariadb"
    let rdb = dbOpen(MariaDB, database, user, password, mariaHost, mariaPort, maxConnections, timeout, shouldDisplayLog=shouldDisplayLog)
    benchmarkScenario(rdb)

when isExistsPostgres:
  proc runPostgres() =
    echo "=== postgres"
    let rdb = dbOpen(PostgreSQL, database, user, password, pgHost, pgPort, maxConnections, timeout, shouldDisplayLog=shouldDisplayLog)
    benchmarkScenario(rdb)

when isExistsSurrealdb:
  proc runSurreal() =
    echo "=== surrealdb"
    let rdb = waitFor dbOpen(SurrealDB, surrealNamespace, surrealDatabase, surrealUser, surrealPassword, surrealHost, surrealPort, maxConnections, timeout, shouldDisplayLog=shouldDisplayLog)
    benchmarkScenario(rdb)


proc main() =
  when isExistsSqlite:
    runSqlite()
  when isExistsMariadb:
    runMariadb()
  when isExistsPostgres:
    runPostgres()
  when isExistsSurrealdb:
    runSurreal()


main()
