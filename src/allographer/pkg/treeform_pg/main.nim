import json, times
import src/pg
import ../../query_builder
import asyncdispatch, threadpool


proc main() {.async.} =
  block:
    let db = db_postgres.open("postgres", "user", "Password!", "allographer")
    let start = cpuTime()
    var rows = newSeq[JsonNode]()
    for i in 1..100:
      rows = rdb().table("users").where("id", "=", i).get()
    echo cpuTime() - start
    echo rows[0]

  block:
    let pool = pg.newAsyncPool("postgres", "user", "Password!", "allographer", 90)
    let start = cpuTime()
    var futures = newSeq[Future[seq[pg.Row]]]()
    var rows = newSeq[pg.Row]()
    for i in 1..100:
      futures.add(
        pool.rows(sql"SELECT * FROM users where id = ?", @[$i])
      )
    for f in futures:
      discard await f
    echo cpuTime() - start

waitFor main()
