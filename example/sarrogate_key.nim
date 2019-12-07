import strformat, json, progress
import bcrypt

import ../src/allographer/query_builder
import ../src/allographer/schema_builder


Schema().create([
  Table().create("auth",[
    Column().increments("id"),
    Column().string("name")
  ], reset=true),
  Table().create("users",[
    Column().increments("user_id"),
    Column().string("name").nullable(),
    Column().string("email").nullable(),
    Column().string("password").nullable(),
    Column().string("salt").nullable(),
    Column().string("address").nullable(),
    Column().date("birth_date").nullable(),
    Column().foreign("auth_id").reference("id").on("auth").onDelete(SET_NULL)
  ], reset=true)
])

# シーダー
RDB().table("auth").insert([
  %*{"name": "admin"},
  %*{"name": "user"}
])
.exec()

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
      "salt": salt,
      "auth_id": authId
    }
  )
  pb.increment()

pb.finish()
RDB().table("users").insert(insertData).exec()
echo RDB().table("users").get()

echo RDB().table("users").find(2, key="user_id")
echo RDB().table("auth").find(1)

RDB().table("users").delete(2, key="user_id").exec()
RDB().table("auth").delete(2).exec()
echo RDB().table("users").limit(3).get()
echo RDB().table("auth").limit(3).get()
