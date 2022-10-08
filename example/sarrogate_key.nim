import std/asyncdispatch
import std/strformat
import std/json
import progress
import bcrypt
import ../src/allographer/query_builder
import ../src/allographer/schema_builder
from ./connections import rdb


rdb.create([
  table("auth",[
    Column.increments("id"),
    Column.string("name")
  ]),
  table("users",[
    Column.increments("user_id"),
    Column.string("name").nullable(),
    Column.string("email").nullable(),
    Column.string("password").nullable(),
    Column.string("address").nullable(),
    Column.date("birth_date").nullable(),
    Column.foreign("auth_id").reference("id").on("auth").onDelete(SET_NULL)
  ])
])

# シーダー
seeder rdb, "auth":
  rdb.table("auth").insert(@[
    %*{"name": "admin"},
    %*{"name": "user"}
  ])
  .waitFor

# プログレスバー
let total = 20
var pb = newProgressBar(total=total) # totalは分母

pb.start()
var insertData: seq[JsonNode]
for i in 1..total:
  let salt = genSalt(10)
  let password = hash(&"password{i}", salt)
  let authId = if i mod 2 == 0: 1 else: 2
  insertData.add(
    %*{
      "name": &"user{i}",
      "email": &"user{i}@gmail.com",
      "password": password,
      "auth_id": authId
    }
  )
  pb.increment()

pb.finish()
rdb.table("users").insert(insertData).waitFor()
echo rdb.table("users").get().waitFor()

echo rdb.table("users").find(2, key="user_id").waitFor()
echo rdb.table("auth").find(1).waitFor()

rdb.table("users").delete(2, key="user_id").waitFor()
rdb.table("auth").delete(2).waitFor()
echo rdb.table("users").limit(3).get().waitFor()
echo rdb.table("auth").limit(3).get().waitFor()
