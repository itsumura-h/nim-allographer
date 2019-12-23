import unittest, json, strformat, progress
import ../src/allographer/schema_builder
import ../src/allographer/query_builder


echo "================ sql injection check ================"

suite "sql injection":
  setup:
    Schema().create([
      Table().create("auth",[
        Column().increments("id"),
        Column().string("auth")
      ], reset=true),
      Table().create("users",[
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
    .exec()

    # プログレスバー
    let total = 10
    var pb = newProgressBar(total=total) # totalは分母

    pb.start()
    var insertData: seq[JsonNode]
    for i in 1..total:
      let authId = if i mod 2 == 0: 1 else: 2
      insertData.add(
        %*{
          "name": &"user{i}",
          "email": &"user{i}@gmail.com",
          "auth_id": authId
        }
      )
      pb.increment()
    pb.finish()

    RDB().table("users").insert(insertData).exec()
  test "1":
    var x = RDB().table("users").where("name", "=", "user1").get()
    var y = RDB().table("users").where("name", "=", "user1' AND 'A' = 'A").get()
    echo x
    echo y
    check x != y
  test "2":
    var x = RDB().table("users").where("name", "=", "user1").get()
    var y = RDB().table("users").where("name", "=", "user1' AND 'A' = 'B").get()
    echo x
    echo y
    check x != y
  test "3":
    var x = RDB().table("users").where("name", "=", "user1").get()
    var y = RDB().table("users").where("name", "=", "user1' OR 'A' = 'B").get()
    echo x
    echo y
    check x != y
  test "4":
    var x = RDB().table("users").where("id", "=", 1).get()
    var y: seq[JsonNode]
    try:
      y = RDB().table("users").where("id", "=", "2-1").get()
    except Exception:
      y = @[]
    echo x
    echo y
    check x != y
  test "5":
    var x = RDB().table("users").select("name", "email")
            .join("auth", "auth.id", "=", "users.auth_id")
            .where("auth.id", "=", 1).get()
    var y: seq[JsonNode]
    try:
      y = RDB().table("users").select("name", "email")
              .join("auth", "auth.id", "=", "users.auth_id")
              .where("auth.id", "=", "2-1").get()
    except Exception:
      y = @[]
    echo x
    echo y
    check x != y
