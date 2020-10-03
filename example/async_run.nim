import json, asyncdispatch, times, strutils, strformat
import ../src/allographer/query_builder
import ../src/allographer/schema_builder

# マイグレーション
schema([
  table("users",[
    Column().increments("id"),
    Column().string("name").nullable(),
    Column().string("Name").nullable(),
    Column().string("email").nullable(),
  ], reset=true)
])


# プログレスバー
let total = 50

var insertData: seq[JsonNode]
for i in 1..total:
  insertData.add(
    %*{
      "name": &"user{i}",
      "Name": &"user{i}",
      "email": &"user{i}@gmail.com",
    }
  )

rdb().table("users").insert(insertData)


const LENGTH = 0..1000

template bench(msg, body) =
  block:
    echo "=== " & msg
    let start = cpuTime()
    body
    echo cpuTime() - start

proc main(){.async.} =
  bench("sync"):
    for i in LENGTH:
      discard rdb().table("users").get()

  bench("async1"):
    for i in LENGTH:
      discard await rdb().table("users").asyncGet()

  bench("async2"):
    var futures: seq[Future[seq[JsonNode]]]
    for i in LENGTH:
      futures.add(
        rdb().table("users").asyncGet()
      )
    for f in futures:
      discard await f

  bench("async1 plain"):
    for i in LENGTH:
      discard await rdb().table("users").asyncGetPlain()

  bench("async2 plain"):
    var futures: seq[Future[seq[Row]]]
    for i in LENGTH:
      futures.add(
        rdb().table("users").asyncGetPlain()
      )
    for f in futures:
      discard await f

proc main2(){.async.} =
  echo "=== asyncGet"
  echo await rdb().table("users").asyncGet()
  echo "=== asyncGetPlain"
  echo await rdb().table("users").asyncGetPlain()
  echo "=== asyncGetRow"
  echo await rdb().table("users").where("id", "=", 2).asyncGetRow()
  echo "=== asyncGetRowPlain"
  echo await rdb().table("users").where("id", "=", 2).asyncGetRowPlain()
  echo "=== asyncFind"
  echo await rdb().table("users").asyncFind(2)
  echo "=== asyncFindPlain"
  echo await rdb().table("users").asyncFindPlain(2)
  echo "=== asyncFirst"
  echo await rdb().table("users").asyncFirst()
  echo "=== asyncFirstPlain"
  echo await rdb().table("users").asyncFirstPlain()

  echo "=== asyncInsert"
  await rdb().table("users").asyncInsert(%*{
    "name": "user100",
    "Name": "user100",
    "email": "user100@gmail.com",
  })
  echo await rdb().table("users").orderBy("id", Desc).asyncFirst()

  echo "=== asyncUpdate"
  await rdb().table("users").where("id", "=", 51).asyncUpdate(%*{
    "name": "newName100"
  })
  echo await rdb().table("users").orderBy("id", Desc).asyncFirst()

  echo "=== asyncDelete"
  await rdb().table("users").where("id", "=", 51).asyncDelete()
  echo await rdb().table("users").orderBy("id", Desc).asyncFirst()


# waitFor main()
waitFor main2()