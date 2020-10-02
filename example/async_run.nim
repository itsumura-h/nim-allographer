import json, asyncdispatch, times
import ../src/allographer/query_builder

const LENGTH = 0..100

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

waitFor main()
