import unittest, json, strformat
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

suite "transaction":
  test "pass db":
    var db = query_builder.db()
    defer: db.close()
    try:
      var user = RDB(db:db).table("users").get()
      echo user
    except:
      discard

  test "transaction macro":
    transaction:
      var user= RDB().table("users").select("id").where("name", "=", "user3").get()
      var id = user["id"].getInt()
      echo id
      user = RDB().table("users").select("name", "email").find(id)
      echo user