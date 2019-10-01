import unittest, json
include allographer


suite "select":
  test "buildSelectSql":
    let query = table("users")
                .select()
                .join("auth", "users.auth_id", "=", "auth.id")
                .where("id", ">", 5)
                .where("name", "LIKE", "user%")
                .orWhere("address", "=", "London")
                .offset(3)
                .limit(5)
    let expect = "SELECT * FROM users JOIN auth ON users.auth_id = auth.id WHERE id > 5 AND name LIKE \"user%\" OR address = \"London\" LIMIT 5 OFFSET 3"
    check buildSelectSql(query) == expect

suite "insert":
  test "insert one row":
    let query = table("users")
                .insert(%*{"name": "John", "address": "London"})
    let expect = "INSERT INTO users (name, address) VALUES (\"John\", \"London\")"
    check query == expect

  test "insert rows":
    let query = table("users")
                .insert(
                  @[
                    %*{"name": "John", "address": "London"},
                    %*{"name": "Paul", "address": "London"}
                  ]
                )
    let expect = "INSERT INTO users (name, address) VALUES (\"John\", \"London\"), (\"Paul\", \"London\")"
    check query == expect

  test "insertDifferentColumns":
    let query = table("users")
                .insertDifferentColumns(
                  [
                    %*{"name": "John", "address": "London"},
                    %*{"name": "Paul", "email": "Paul@gmail.com"}
                  ]
                )
    let expect = @[
      "INSERT INTO users (name, address) VALUES (\"John\", \"London\")",
      "INSERT INTO users (name, email) VALUES (\"Paul\", \"Paul@gmail.com\")"
    ]
    check query == expect

suite "update":
  test "update":
    let query = table("users")
                .join("auth", "users.auth_id", "=", "auth.id")
                .where("users.id", ">", 3)
                .orWhere("users.email", "LIKE", "John%")
                .limit(10)
                .offset(3)
                .update(
                  %*{"user.name": "Paul", "user.auth_id": 2},
                )
    let expect = "UPDATE users SET user.name = \"Paul\", user.auth_id = 2 JOIN auth ON users.auth_id = auth.id WHERE users.id > 3 OR users.email LIKE \"John%\" LIMIT 10 OFFSET 3"
    check query == expect

suite "delete":
  test "delete without id":
    let query = table("users")
                .join("auth", "users.auth_id", "=", "auth.id")
                .where("users.id", ">", 3)
                .orWhere("users.email", "LIKE", "John%")
                .limit(10)
                .offset(3)
                .delete()
    let expect = "DELETE FROM users JOIN auth ON users.auth_id = auth.id WHERE users.id > 3 OR users.email LIKE \"John%\" LIMIT 10 OFFSET 3"
    check query == expect

    test "delete with id":
      let query = table("users")
                  .delete(3)
      let expect = "DELETE FROM users WHERE id = 3"
      check query == expect