import std/asyncdispatch
when NimMajor == 2:
  import db_connector/db_postgres
else:
  import std/db_postgres

import std/json
import std/random
import std/os
import std/options
import std/strutils
import std/strformat
import std/sequtils
import std/times
import ../src/allographer/connection
import ../src/allographer/schema_builder
import ../src/allographer/query_builder


randomize()
let rdb = dbOpen(PostgreSQL, "database", "user", "pass", "postgres", 5432, 95, 30, shouldDisplayLog=false)
let stdRdb = open("postgres:5432", "user", "pass", "database")
const range1_10000 = 1..10000

proc migrate() {.async.} =
  echo "=== start migration"
  rdb.create(
    table("World", [
      Column.increments("id"),
      Column.integer("randomNumber").default(0)
    ]),
    table("Fortune", [
      Column.increments("id"),
      Column.string("message")
    ])
  )

  seeder(rdb, "World"):
    var data = newSeq[JsonNode]()
    for i in 1..10000:
      data.add(
        %*{"randomNumber": rand(1..10000)}
      )
    await rdb.table("World").insert(data)

  seeder(rdb, "Fortune"):
    data = @[
      %*{"id": 1, "message": "fortune: No such file or directory"},
      %*{"id": 2, "message": "A computer scientist is someone who fixes things that aren''t broken."},
      %*{"id": 3, "message": "After enough decimal places, nobody gives a damn."},
      %*{"id": 4, "message": "A bad random number generator: 1, 1, 1, 1, 1, 4.33e+67, 1, 1, 1"},
      %*{"id": 5, "message": "A computer program does what you tell it to do, not what you want it to do."},
      %*{"id": 6, "message": "Emacs is a nice operating system, but I prefer UNIX. — Tom Christaensen"},
      %*{"id": 7, "message": "Any program that runs right is obsolete."},
      %*{"id": 8, "message": "A list is only as strong as its weakest link. — Donald Knuth"},
      %*{"id": 9, "message": "Feature: A bug with seniority."},
      %*{"id": 10, "message": "Computers make very fast, very accurate mistakes."},
      %*{"id": 11, "message": """<script>alert("This should not be displayed in a browser alert box.");</script>"""},
      %*{"id": 12, "message": "フレームワークのベンチマーク"},
    ]
    await rdb.table("Fortune").insert(data)
  echo "=== finish migration"


let getFirstPrepare = stdRdb.prepare("getFirst", sql""" SELECT * FROM "World" WHERE id = $1 LIMIT 1 """, 1)
let updatePrepare = stdRdb.prepare("updatePrepare", sql""" UPDATE "World" SET "randomNumber" = $1 WHERE id = $2 """, 2)

const countNum = 500

proc query():Future[seq[JsonNode]] {.async.} =
  var futures = newSeq[Future[seq[string]]](countNum)
  for i in 1..countNum:
    let n = rand(range1_10000)
    futures[i-1] = rdb.select().table("World").findPlain(n)
  let resp = all(futures).await
  let response = resp.map(
    proc(x:seq[string]):JsonNode =
      if x.len > 0: %*{"id": x[0].parseInt, "randomNumber": x[1].parseInt}
      else: newJObject()
  )
  return response

proc queryRaw():Future[seq[JsonNode]] {.async.} =
  var futures = newSeq[Future[seq[string]]](countNum)
  for i in 1..countNum:
    let n = rand(range1_10000)
    futures[i-1] = rdb.raw(""" SELECT * from "World" WHERE id = ? LIMIT 1 """, %[n]).firstPlain()
  let resp = all(futures).await
  let response = resp.map(
    proc(x:seq[string]):JsonNode =
      if x.len > 0: %*{"id": x[0].parseInt, "randomNumber": x[1].parseInt}
      else: newJObject()
  )
  return response


proc queryStd():Future[seq[JsonNode]] {.async.} =
  var resp:seq[Row]
  for i in 1..countNum:
    resp.add(stdRdb.getRow(getFirstPrepare, i))
  let response = resp.map(
    proc(x:seq[string]):JsonNode =
      %*{"id": x[0].parseInt, "randomNumber": x[1]}
    )
  return response


proc update():Future[seq[JsonNode]] {.async.} =
  var response = newSeq[JsonNode](countNum)
  var futures = newSeq[Future[void]](countNum)
  for i in 1..countNum:
    let index = rand(range1_10000)
    let number = rand(range1_10000)
    futures[i-1] = (proc():Future[void] =
      discard rdb.select("id", "randomNumber").table("World").findPlain(index)
      rdb.table("World").where("id", "=", index).update(%*{"randomNumber": number})
    )()
    response[i-1] = %*{"id":index, "randomNumber": number}
  await all(futures)
  return response


proc updateRaw():Future[seq[JsonNode]] {.async.} =
  var response = newSeq[JsonNode](countNum)
  var futures = newSeq[Future[void]](countNum)
  for i in 1..countNum:
    let index = rand(range1_10000)
    let number = rand(range1_10000)
    futures[i-1] = (proc():Future[void] =
      discard rdb.raw(""" SELECT FROM "World" WHERE id = ? LIMIT 1 """, %[index]).firstPlain()
      rdb.raw(""" UPDATE "World" SET "randomNumber" = ? WHERE id = ? """, %[number, index]).exec()
    )()
    response[i-1] = %*{"id":index, "randomNumber": number}
  await all(futures)
  return response


proc updateRawStd():Future[seq[JsonNode]] {.async.} =
  var response = newSeq[JsonNode](countNum)
  var futures = newSeq[Future[void]](countNum)
  for i in 1..countNum:
    let index = rand(range1_10000)
    let number = rand(range1_10000)
    futures[i-1] = (proc():Future[void] =
      discard stdRdb.getRow(getFirstPrepare, $index)
      rdb.raw(""" UPDATE "World" SET "randomNumber" = ? WHERE id = ? """, %[number, index]).exec()
    )()
    response[i-1] = %*{"id":index, "randomNumber": number}
  await all(futures)
  return response


proc timeProcess[T](name:string, cb:proc():Future[T]) {.async.}=
  var start = 0.0
  var eachTime = 0.0
  var sumTime = 0.0
  const times = 5
  var resultStr = ""

  for i in 1..times:
    sleep(100)
    start = cpuTime()
    discard cb().await
    eachTime = cpuTime() - start
    sumTime += eachTime
    if i > 1: resultStr.add("\n")
    resultStr.add(&"|{i}|{eachTime}|")

  echo name
  echo "|num|time|"
  echo "|---|---|"
  echo resultStr
  echo fmt"|Avg|{sumTime / times}|"
  echo ""

proc main() =
  migrate().waitFor

  timeProcess("query", query).waitFor
  # timeProcess("queryRaw", queryRaw).waitFor
  # timeProcess("queryStd", queryStd).waitFor
  # timeProcess("update", update).waitFor
  # timeProcess("updateRaw", updateRaw).waitFor
  # timeProcess("updateRawStd", updateRawStd).waitFor


main()
