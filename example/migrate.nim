import strformat, json
import bcrypt
import ../src/allographer/QueryBuilder
import ../src/allographer/SchemaBuilder
# import allographer/QueryBuilder
# import allographer/SchemaBuilder


# マイグレーション
Model().new("auth",[
  Schema().increments("id"),
  Schema().string("auth")
])

Model().new("users",[
  Schema().increments("id"),
  Schema().string("name").nullable(),
  Schema().string("email").nullable(),
  Schema().string("password").nullable(),
  Schema().string("salt").nullable(),
  Schema().string("address").nullable(),
  Schema().date("birth_date").nullable(),
  Schema().foreign("auth_id").reference("id").on("auth").onDelete(SET_NULL)
])

# シーダー
RDB().table("auth").insert([
  %*{"auth": "admin"},
  %*{"auth": "user"}
])
.exec()


var insertData: seq[JsonNode]
for i in 1..100:
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
RDB().table("users").insert(insertData).exec()
