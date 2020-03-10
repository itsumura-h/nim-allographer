import json, strformat, macros
import bcrypt
import ../src/allographer/schema_builder
import ../src/allographer/query_builder

schema([
  table("auth",[
    Column().increments("id"),
    Column().string("auth")
  ], reset=true),
  table("users",[
    Column().increments("id"),
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
  %*{"auth": "admin"},
  %*{"auth": "user"}
])


var insertData: seq[JsonNode]
for i in 1..30:
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

RDB().table("users").insert(insertData)

transaction:
  echo RDB().table("users").select("name", "email").where("id", "=", 2).get()
  # echo RDB().table("users").select("name", "email").where("id", "=", 3).get()