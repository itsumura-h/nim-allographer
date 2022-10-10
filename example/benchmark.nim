import std/asyncdispatch
import std/json
import std/random
import std/strutils
import std/sequtils
import std/times
import ../src/allographer/schema_builder
import ../src/allographer/query_builder
from connections import rdb


randomize()

const range1_10000 = 1..10000

proc migrate() {.async.} =
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

  seeder rdb, "World":
    var data = newSeq[JsonNode]()
    for i in 1..10000:
      data.add(
        %*{"randomNumber": rand(1..10000)}
      )
    await rdb.table("World").insert(data)

  seeder rdb, "Fortune":
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


proc update() {.async.} =
  const countNum = 500
  var response = newSeq[JsonNode](countNum)
  var updateFutures = newSeq[Future[void]](countNum)
  for i in 1..countNum:
    let index = rand(range1_10000)
    let number = rand(range1_10000)
    updateFutures[i-1] = (
      proc() {.async.} =
        discard rdb.table("World").select("id", "randomNumber").findPlain(index)
        discard rdb.table("World").where("id", "=", index).update(%*{"randomNumber": number})
        response[i-1] = %*{"id":index, "randomNumber": number}
    )()
    response[i-1] = %*{"id":index, "randomNumber": number}
  await all(updateFutures)


proc query() {.async.} =
  const countNum = 100
  var futures = newSeq[Future[seq[string]]](countNum)
  for i in 1..countNum:
    let n = rand(1..10000)
    futures[i-1] = rdb.table("World").findPlain(n)
  let resp = all(futures).await
  let response = resp.map(
    proc(x:seq[string]):JsonNode =
      if x.len > 0: %*{"id": x[0].parseInt, "randomnumber": x[1]}
      else: newJObject()
  )
  echo response


proc main() {.async.} =
  migrate().waitFor
  # waitFor main()
  let start = cpuTime()
  for i in 1..20:
    update().await
    query().await
    echo "===== ", i
  echo cpuTime() - start

main().waitFor