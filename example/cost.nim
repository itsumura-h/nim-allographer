import times, json, strformat
import ../src/allographer/query_builder
import ../src/allographer/schema_builder

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
  for _ in 0..40:
    discard RDB().table("users").get()

bench("getPlain"):
  for _ in 0..40:
    discard RDB().table("users").getPlain()

bench("get transaction"):
  transaction:
    for _ in 0..40:
      discard RDB().table("users").get()

bench("getPlain transaction"):
  transaction:
    for _ in 0..40:
      discard RDB().table("users").getPlain()
