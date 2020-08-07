import times, json, strformat, sequtils
import ../src/allographer/query_builder
import ../src/allographer/query_builder/builders
import ../src/allographer/schema_builder

const
  LENGTH = 100

schema([
  table("auth",[
    Column().increments("id"),
    Column().string("auth")
  ], reset=true),
  table("users",[
    Column().increments("id"),
    Column().string("name").nullable(),
    Column().string("email").nullable(),
    Column().string("address").nullable(),
    Column().foreign("auth_id").reference("id").on("auth").onDelete(SET_NULL)
  ], reset=true)
])

# seeder
RDB().table("auth").insert([
  %*{"auth": "admin"},
  %*{"auth": "user"}
])

var users: seq[JsonNode]
for i in 1..10:
  let authId = if i mod 2 == 0: 2 else: 1
  users.add(
    %*{
      "name": &"user{i}",
      "email": &"user{i}@gmail.com",
      "auth_id": authId
    }
  )

RDB().table("users").insert(users)

template bench(msg, body) =
  block:
    echo "=== " & msg
    let start = cpuTime()
    body
    echo cpuTime() - start

bench("get"):
  for _ in 0..LENGTH:
    discard RDB().table("users").get()

# bench("getPlain"):
#   for _ in 0..LENGTH:
#     discard RDB().table("users").getPlain()

bench("get transaction"):
  transaction:
    for _ in 0..LENGTH:
      discard RDB().table("users").get()

# bench("getPlain transaction"):
#   transaction:
#     for _ in 0..LENGTH:
#       discard RDB().table("users").getPlain()

# bench("getRaw"):
#   for _ in 0..LENGTH:
#     discard RDB().raw("SELECT * from users").getRaw()

# bench("getRaw transaction"):
#   transaction:
#     for _ in 0..LENGTH:
#       discard RDB().raw("SELECT * from users").getRaw()

# bench("embedded"):
#   for _ in 0..LENGTH:
#     let db = db()
#     defer: db.close()
#     discard db.getAllRows(sql "SELECT * from users")

bench("embedded transaction"):
  let db = db()
  defer: db.close()
  db.exec(sql"BEGIN")
  for _ in 0..LENGTH:
    discard db.getAllRows(sql "SELECT * from users")
  db.exec(sql"COMMIT")

# bench("getAllRows"):
#   let sqlString = RDB().table("users").selectBuilder().sqlString
#   let args = newSeq[system.string]()
#   let db = db()
#   defer: db.close()
#   for _ in 0..LENGTH:
#     discard getAllRows(db, sql sqlString, args)

# bench("getPlain builder"):
#   transaction:
#     let rdb = RDB().table("users")
#     for _ in 0..LENGTH:
#       discard RDB().table("users")

bench("getPlain exec"):
  transaction:
    for _ in 0..LENGTH:
      discard RDB().table("users").getPlain()

bench("make sql"):
  for _ in 0..LENGTH:
    discard RDB().table("users").where("id", "=", 1).limit(1).toSql()
