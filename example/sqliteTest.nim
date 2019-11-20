import json, strformat

import progress
import ../src/allographer/schema_builder
import ../src/allographer/query_builder

Schema().create([
  Table().create("users", [
    Column().increments("id"),
    Column().string("name"),
    Column().string("email")
  ], isRebuild=true)
])

# プログレスバー
let total = 1000000
var pb = newProgressBar(total=total) # totalは分母

var users: seq[JsonNode]
pb.start()
for i in 1..total:
  users.add(%*{
    "id": i,
    "name": &"user{i}",
    "email": &"user{i}@gmail.com"
  })
  pb.increment()
  # if i mod 100000 == 0:
  #   RDB().table("users").insert(users).exec()
  #   users = @[]
RDB().table("users").insert(users).exec()
pb.finish()
