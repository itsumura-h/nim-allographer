import unittest, json
import ../src/allographer/QueryBuilder
include ../src/query_builder/exec

suite "select":
  test "all":
    var sql = RDB()
              .table("users")
              .select("id", "email")
              .where("name", "=", "John")
              .where("id", "=", 3)
              .orWhere("name", "=", "George")
              .orWhere("name", "=", "Paul")
              .orWhere("id", "=", 4)
              .orWhere("id", "=", 5)
              .join("auth", "auth.id", "=", "auth_id")
              .join("auth", "auth.id", "=", "auth_id")
              .limit(10)
              .offset(5)
              .checkSql()
              .sqlString
    check sql == "SELECT id, email FROM users JOIN auth ON auth.id = auth_id JOIN auth ON auth.id = auth_id WHERE name = \"John\" AND id = 3 OR name = \"George\" OR name = \"Paul\" OR id = 4 OR id = 5 LIMIT 10 OFFSET 5"

  test "select * where int and string or int":
    var sql = RDB()
              .table("users")
              .select()
              .where("id", "=", 3)
              .where("name", "LIKE", "%user%")
              .orWhere("id", "=", 4)
              .checkSql()
              .sqlString
    check sql == "SELECT * FROM users WHERE id = 3 AND name LIKE \"%user%\" OR id = 4"

  test "select * id = int":
    var result = RDB()
              .table("users")
              .find(1)
    check result["name"].getStr == "user1"

suite "insert":
  test "insert one":
    var sql = RDB()
              .table("users")
              .insert(%*{"name": "John", "email": "John@gmail.com"})
              .sqlString
    check sql == "INSERT INTO users (name, email) VALUES (\"John\", \"John@gmail.com\")"

  test "insert multi":
    var sql = RDB()
              .table("users")
              .insert([
                %*{"name": "John", "email": "John@gmail.com"},
                %*{"name": "Paul", "email": "Paul@gmail.com"}
              ])
              .sqlString
    check sql == "INSERT INTO users (name, email) VALUES (\"John\", \"John@gmail.com\"), (\"Paul\", \"Paul@gmail.com\")"

  test "inserts":
    var sql = RDB()
              .table("users")
              .inserts([
                %*{"name": "John"},
                %*{"email": "Paul@gmail.com"}
              ])
              .sqlStringSeq
    check sql[0] == "INSERT INTO users (name) VALUES (\"John\")"
    check sql[1] == "INSERT INTO users (email) VALUES (\"Paul@gmail.com\")"

suite "update":
  test "update where":
    var sql = RDB()
              .table("users")
              .where("name", "=", "John")
              .update(%*{"name": "Paul", "email": "Paul@gmail.com"})
              .sqlStringSeq
    check sql[0] == "UPDATE users SET name = \"Paul\", email = \"Paul@gmail.com\" WHERE name = \"John\""

suite "delete":
  test "delete where":
    var sql = RDB()
              .table("users")
              .where("name", "=", "David")
              .delete()
              .sqlStringSeq
    check sql[0] == "DELETE FROM users WHERE name = \"David\""

  test "delete by id":
    var sql = RDB()
              .table("users")
              .delete(4)
              .sqlStringSeq
    check sql[0] == "DELETE FROM users WHERE id = 4"
