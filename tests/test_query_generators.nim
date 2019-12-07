import unittest

import ../src/allographer/query_builder_pkg/grammars
include ../src/allographer/query_builder_pkg/generators

suite "generators":
  test "selectSql id":
    let t = RDB(
      query: %*{"select": ["id"]}
    )
    check t.selectSql().sqlString == "SELECT id"

  test "select id, name":
    let t = RDB(
      query: %*{"select": ["id", "name"]}
    )
    check t.selectSql().sqlString == "SELECT id, name"

  test "select *":
    let t = RDB(
      query: %*{}
    )
    check t.selectSql().sqlString == "SELECT *"

  test "from":
    let t = RDB(
      query: %*{"table": "samples"}
    )
    check t.fromSql().sqlString == " FROM samples"
  
  test "select by id":
    let t = RDB()
    check t.selectByIdSql(3, key="id").sqlString == " WHERE id = 3 LIMIT 1"

  test "join":
    let t = RDB(
      query: %*{
        "join": [
          {
            "table": "table",
            "column1": "table.column1",
            "symbol": "=",
            "column2": "sample.column1"
          },
          {
            "table": "table2",
            "column1": "table2.column1",
            "symbol": "=",
            "column2": "table1.column1"
          }
        ]
      }
    )
    check t.joinSql().sqlString == " JOIN table ON table.column1 = sample.column1 JOIN table2 ON table2.column1 = table1.column1"

  test "where":
    let t = RDB(
      query: %*{
        "where": [
          {
            "column": "id1",
            "symbol": "<",
            "value": 3
          },
          {
            "column": "id2",
            "symbol": ">",
            "value": 5
          }
        ]
      }
    )
    check t.whereSql().sqlString == " WHERE id1 < 3 AND id2 > 5"

  test "orWhere":
    let t = RDB(
      query: %*{
        "or_where": [
          {
            "column": "id1",
            "symbol": "<",
            "value": 3
          },
          {
            "column": "id2",
            "symbol": ">",
            "value": 5
          }
        ]
      }
    )
    check t.orWhereSql().sqlString == " WHERE id1 < 3 OR id2 > 5"

  test "limit":
    let t = RDB(
      query: %*{
        "limit": 3
      }
    )
    check t.limitSql().sqlString == " LIMIT 3"

  test "offset":
    let t = RDB(
      query: %*{
        "offset": 5
      }
    )
    check t.offsetSql().sqlString == " OFFSET 5"

  test "insert":
    let t = RDB(
      query: %*{
        "table": "test"
      }
    )
    check t.insertSql().sqlString == "INSERT INTO test"

  test "insert value":
    let t = RDB()
    let items = %*{
      "name": "John",
      "email": "John@gmail.com"
    }
    check t.insertValueSql(items).sqlString == " (name, email) VALUES (\"John\", \"John@gmail.com\")"

  test "insert values":
    let t = RDB()
    let items = [
      %*{"name": "John", "email": "John@gmail.com"},
      %*{"name": "Paul", "email": "Paul@gmail.com"},
    ]
    check t.insertValuesSql(items).sqlString == " (name, email) VALUES (\"John\", \"John@gmail.com\"), (\"Paul\", \"Paul@gmail.com\")"


  test "update":
    let t = RDB(
      query: %*{"table": "test"}
    )
    check t.updateSql().sqlString == "UPDATE test SET "

  test "update values":
    let t = RDB()
    let items = %*{
      "name": "John",
      "email": "John@gmail.com"
    }
    check t.updateValuesSql(items).sqlString == "name = \"John\", email = \"John@gmail.com\""

  test "delete":
    check RDB().deleteSql().sqlString == "DELETE"

  test "delete by id":
    check RDB().deleteByIdSql(3, key="id").sqlString == " WHERE id = 3"
