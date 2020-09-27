import pg, asyncdispatch, strutils, json, times

const
  LENGTH = 1..200

template bench(msg, body) =
  block:
    echo "=== " & msg
    let start = cpuTime()
    body
    echo cpuTime() - start

proc main1() =
  # sync version
  bench("main1"):
    let pg = open("", "user", "Password!", "host=postgres port=5432 dbname=allographer")
    let rows = waitFor pg.rows(sql"SELECT ?, pg_sleep(1), 'hi there';", @[$1])

proc main2() {.async.} =
  # run 20 queries at once on a 2 connecton pool
  let pool = newAsyncPool("postgres", "user", "Password!", "allographer", 90)
  var futures = newSeq[Future[seq[Row]]]()
  bench("main2"):
    for i in LENGTH:
      futures.add pool.rows(sql"SELECT ?, pg_sleep(1);", @[$i])
    for f in futures:
      var res = await f
  pool.disconnect()

proc main3() {.async.} =
  var futures = newSeq[Future[seq[JsonNode]]]()

  # let pg = open("", "user", "Password!", "host=postgres port=5432 dbname=allographer")  
  # bench("main3 sync"):
  #   for i in LENGTH:
  #     let rows = waitFor pg.rows(sql"SELECT * FROM users", @[])

  let pool = newAsyncPool("postgres", "user", "Password!", "allographer", 90)
  bench("main3 async"):
    for i in LENGTH:
      futures.add pool.asyncGetAllRows(sql"SELECT * FROM users LIMIT 10", @[])
    for f in futures:
      var res = await f
      # echo res

    # for i in LENGTH:
    #   discard await pool.asyncGetAllRows(sql"SELECT * FROM users LIMIT 10", @[])


proc errors() =
  # sync version
  let pg = open("", "user", "Password!", "host=postgres port=5432 dbname=allographer")
  block:
    echo "valid query returns 1 result"
    let rows = waitFor pg.rows(sql"select 1;", @[])
    echo rows
  block:
    echo "valid query retirms 0 results"
    let rows = waitFor pg.rows(sql"select 1 limit 0;", @[])
    echo rows
  block:
    echo "invalid query"
    var rows = newSeq[Row]()
    try:
      rows = waitFor pg.rows(sql"invalid sql;", @[])
    except PGError:
      echo $(getCurrentExceptionMsg()).split("\n")[0]
    echo rows
  block:
    echo "invalid table"
    var rows = newSeq[Row]()
    try:
      rows = waitFor pg.rows(sql"select * from invalid_table;", @[])
    except PGError:
      echo $(getCurrentExceptionMsg()).split("\n")[0]
    echo rows


# errors()
# main1()
# waitFor main2()
echo "=".repeat(50)
waitFor main3()