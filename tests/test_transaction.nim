import unittest, json, strformat, options
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
rdb().table("auth").insert([
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

rdb().table("users").insert(users)

suite "transaction":
  test "not in transaction":
    var db = query_builder.db()
    defer: db.close()
    try:
      var user = RDB(db:db).table("users").get()
      echo user
    except:
      discard

  test "in transaction":
    transaction:
      var user= rdb().table("users").select("id").where("name", "=", "user3").first.get
      var id = user["id"].getInt()
      echo id
      user = rdb().table("users").select("name", "email").find(id).get
      echo user

  test "rollback success":
    block:
      let db = query_builder.db()
      defer: db.close()
      try:
        db.exec(sql"BEGIN")
        RDB(db:db).table("users").insert(%*{"id": 9, "name": "user9", "email": "user9@example.com"})
        db.exec(sql"COMMIT")
      except:
        echo "=== rollback"
        echo getCurrentExceptionMsg()
        db.exec(sql"ROLLBACK")
    echo rdb().table("users").find(11)
    echo db.type

  test "rollback":
    transaction:
      echo "=== in transaction"
      rdb().table("users").insert(%*{"id": 9, "name": "user9", "email": "user9@example.com"})
      echo "=== end of transaction"
    echo "=== out of transaction"
    echo rdb().table("users").find(11)

  test "insertID":
    transaction:
      let id = rdb().table("users")
                .insertID(%*{"name": "user11", "email": "user11@example.com"})
      echo id
    echo rdb().table("users").max("id")

  test "insertID":
    transaction:
      let id = rdb().table("users")
                .insertID([
                  %*{"name": "user11", "email": "user11@example.com"},
                  %*{"name": "user12", "email": "user12@example.com"}
                ])
      echo id
    echo rdb().table("users").max("id")

  test "insertsID":
    transaction:
      discard rdb().table("users").insertsID(
        [
          %*{"name": "John", "email": "John@gmail.com", "address": "London"},
          %*{"name": "Paul", "email": "Paul@gmail.com", "address": "London"},
          %*{"name": "George", "birth_date": "1943-02-25", "address": "London"},
        ]
      )
    echo rdb().table("users").where("id", ">", 10).get()
