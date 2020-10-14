import strformat, json, progress
import bcrypt
import ../src/allographer/query_builder
import ../src/allographer/schema_builder
# import allographer/query_builder
# import allographer/schema_builder


# マイグレーション
schema([
  table("Auth",[
    Column().increments("id"),
    Column().string("auth")
  ], reset=true),
  table("Users",[
    Column().increments("id"),
    Column().string("Name").nullable(),
    Column().string("email").nullable(),
    Column().string("password").nullable(),
    Column().string("address").nullable(),
    Column().date("birth_date").nullable(),
    Column().foreign("auth_id").reference("id").on("Auth").onDelete(SET_NULL)
  ], reset=true)
])

# シーダー
rdb().table("Auth").insert([
  %*{"auth": "admin"},
  %*{"auth": "user"}
])

# プログレスバー
let total = 10
var pb = newProgressBar(total=total) # totalは分母

pb.start()
var insertData: seq[JsonNode]
for i in 1..total:
  let salt = genSalt(10)
  let password = hash(&"password{i}", salt)
  let authId = if i mod 2 == 0: 1 else: 2
  insertData.add(
    %*{
      "Name": &"user{i}",
      "email": &"user{i}@gmail.com",
      "password": password,
      "auth_id": authId
    }
  )
  pb.increment()

pb.finish()
rdb().table("Users").insert(insertData)
