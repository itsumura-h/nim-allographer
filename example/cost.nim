import times, json
import ../src/allographer/query_builder
import ddd/service
import setup

const LENGTH = 1000

setup()

bench("embedded"):
  for _ in 0..LENGTH:
    let db = db()
    defer: db.close()
    discard db.getAllRows(sql "SELECT * from users")

bench("embedded transaction"):
  let db = db()
  defer: db.close()
  db.exec(sql"BEGIN")
  for _ in 0..LENGTH:
    discard db.getAllRows(sql "SELECT * from users")
  db.exec(sql"COMMIT")

bench("get"):
  for _ in 0..LENGTH:
    discard RDB().table("users").get()

bench("DDD"):
  let db = db()
  defer: db.close()
  let service = newService(db)
  for i in 1..LENGTH+1:
    discard service.getUsers()
    discard service.getUser(i)

bench("get transaction"):
  transaction:
    for _ in 0..LENGTH:
      discard RDB().table("users").get()

bench("getPlain transaction"):
  transaction:
    for _ in 0..LENGTH:
      discard RDB().table("users").getPlain()

bench("make sql"):
  for _ in 0..LENGTH:
    discard RDB().table("users").where("id", "=", 1).limit(1).toSql()
