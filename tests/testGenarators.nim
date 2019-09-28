import unittest, json
include ../src/generators

include ../src/grammars

suite "selectSql":
  test "select *":
    let query = table("users").select()
    check selectSql(query) == "SELECT *" 
  test "select {columns}":
    let query = table("users").select("id", "name")
    check selectSql(query) == "SELECT id, name"

suite "selectCountSql":
  test "select count(*)":
    let query = table("users").select()
    check selectCountSql(query) == "SELECT COUNT(*)"
  test "select count({columns})":
    let query = table("users").select("id", "name")
    check selectCountSql(query) == "SELECT COUNT(id), COUNT(name)"

suite "fromSql":
  test "from {table}":
    let query = table("users")
    check fromSql("", query) == " FROM users"

suite "joinSql":
  test "join {table} on {column1} {symbol} {column2}":
    let query = table("users").join("auth", "users.auth_id", "=", "auth.id")
    check joinSql("", query) == " JOIN auth ON users.auth_id = auth.id"

suite "whereSql":
  test "one where":
    let query = table("users").where("id", "<", 3)
    check whereSql("", query) == " WHERE id < 3"
  test "multi where":
    let query = table("users").where("id", "<", 3).where("name", "=", "John")
    check whereSql("", query) == " WHERE id < 3 AND name = \"John\""

suite "orWhereSql":
  test "one orWhere":
    let query = table("users").orWhere("id", "<", 3)
    check orWhereSql("", query) == " WHERE id < 3"
  test "multi orWhere":
    let query = table("users").where("id", "<", 3).orWhere("name", "=", "John")
    check orWhereSql(" WHERE id < 3", query) == " WHERE id < 3 OR name = \"John\""

suite "limit":
  test "limit {n}":
    let query = table("users").limit(3)
    check limitSql("", query) == " LIMIT 3"

suite "offset":
  test "offset {n}":
    let query = table("users").offset(2)
    check offsetSql("", query) == " OFFSET 2"

suite "insertSql":
  test "insert into {table}":
    let query = table("users")
    check insertSql(query) == "INSERT INTO users"

suite "insertValuesSqlByJsonNode":
  test " ({columns}) VALUES ({values})":
    let query = insertValuesSqlByJsonNode("", %*{
      "name": "John", "email": "John@gmail.com", "address": "London"
    })
    check query ==
      " (name, email, address) VALUES (\"John\", \"John@gmail.com\", \"London\")"

suite "insertMultiValuesSql":
  test " ({columns}) values {values}":
    let query = insertMultiValuesSql("", @[
      %*{"name": "John", "email": "John@gmail.com", "address": "London"},
      %*{"name": "Mick", "email": "Mick@gmail.com", "address": "Paris"},
    ])
    check query ==
      " (name, email, address) VALUES (\"John\", \"John@gmail.com\", \"London\"), (\"Mick\", \"Mick@gmail.com\", \"Paris\")"

suite "updateSql":
  test "update {table} set ":
    let query = table("users")
    check updateSql(query) == "UPDATE users SET "

suite "updateValuesSql":
  test "{key} = {value}":
    let conditions = %*{"name": "John", "address": "London"}
    check updateValuesSql("", conditions) == "name = \"John\", address = \"London\""

suite "deleteSql":
  test "delete {table}":
    check deleteSql() == "DELETE"