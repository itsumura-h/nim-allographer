import times, json, asyncdispatch
import ../src/allographer/query_builder
import ddd/service
import setup

const LENGTH = 1000

let db = db()
setup()

bench("embedded"):
  for _ in 0..LENGTH:
    discard db.getAllRows(sql "SELECT * from users")

bench("embedded transaction"):
  db.exec(sql"BEGIN")
  for _ in 0..LENGTH:
    discard db.getAllRows(sql "SELECT * from users")
  db.exec(sql"COMMIT")

bench("get"):
  for _ in 0..LENGTH:
    discard rdb().table("users").get()

bench("get2"):
  for _ in 0..LENGTH:
    discard rdb().table("users").get()

bench("DDD"):
  let service = newService()
  for i in 1..LENGTH+1:
    discard service.getUsers()
    discard service.getUser(i)

bench("get transaction"):
  transaction:
    for _ in 0..LENGTH:
      discard rdb().table("users").get()

bench("getPlain transaction"):
  transaction:
    for _ in 0..LENGTH:
      discard rdb().table("users").getPlain()

bench("make sql"):
  for _ in 0..LENGTH:
    discard rdb().table("users").where("id", "=", 1).limit(1).toSql()

proc access():Future[seq[JsonNode]] =
  let re = newFuture[seq[JsonNode]]("")
  let res = rdb().table("users").get()
  re.complete(res)
  return re

bench("async"):
  for _ in 0..LENGTH:
    discard waitFor access()
