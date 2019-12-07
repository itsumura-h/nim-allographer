import unittest, json
include ../src/allographer/query_builder_pkg/builders

suite "builders":
  test "select *":
    let t = RDB(
      query: %*{
        "table": "sample",
        "join": [
          %*{"table": "t1", "column1": "t1.c1", "symbol": "=", "column2": "t.c1"},
          %*{"table": "t2", "column1": "t2.c2", "symbol": "=", "column2": "t1.c2"}
        ],
        "where": [
          %*{"column": "name", "symbol": "=", "value": "John"},
          %*{"column": "name", "symbol": "=", "value": "Paul"}
        ],
        "or_where": [
          %*{"column": "name", "symbol": "=", "value": "John"},
          %*{"column": "name", "symbol": "=", "value": "Paul"}
        ],
        "limit": 5,
        "offset": 3
      }
    )
    check t.selectBuilder().sqlString == "SELECT * FROM sample JOIN t1 ON t1.c1 = t.c1 JOIN t2 ON t2.c2 = t1.c2 WHERE name = \"John\" AND name = \"Paul\" OR name = \"John\" OR name = \"Paul\" LIMIT 5 OFFSET 3"

  test "select id, name":
    let t = RDB(
      query: %*{
        "table": "sample",
        "select": ["id", "name"]
      }
    )
    check t.selectBuilder().sqlString == "SELECT id, name FROM sample"

  test "select by id":
    let t = RDB(
      query: %*{
        "table": "sample"
      }
    )
    check t.selectFindBuilder(3, key="id").sqlString == "SELECT * FROM sample WHERE id = 3 LIMIT 1"

# =============================================================================

  test "insert":
    let t = RDB(
      query: %*{"table": "sample"}
    )
    check t.insertSql().sqlString == "INSERT INTO sample"

  test "insert value":
    var t = RDB(
      query: %*{"table": "sample"}
    )
    t = t.insertValueBuilder(
      %*{"name": "John", "email":"John@gmail.com"}
    )
    check t.sqlString == "INSERT INTO sample (name, email) VALUES (\"John\", \"John@gmail.com\")"

  test "insert values":
    var t = RDB(
      query: %*{"table": "sample"}
    )
    t = t.insertValuesBuilder(
      [
        %*{"name": "John"},
        %*{"name": "Paul"}
      ]
    )
    check t.sqlString == "INSERT INTO sample (name) VALUES (\"John\"), (\"Paul\")"

# =============================================================================

  test "update":
    var t = RDB(
      query: %*{
        "table": "sample",
        "join": [
          %*{"table": "t1", "column1": "t1.c1", "symbol": "=", "column2": "sample.c1"},
          %*{"table": "t2", "column1": "t2.c1", "symbol": "=", "column2": "t1.c1"}
        ],
        "where": [
          %*{"column": "c1", "symbol": "=", "value": "v1"},
          %*{"column": "c2", "symbol": "=", "value": "v2"}
        ],
        "or_where": [
          %*{"column": "or_c1", "symbol": "=", "value": "or_v1"},
          %*{"column": "or_c2", "symbol": "=", "value": "or_v2"}
        ],
        "limit": 5,
        "offset": 3
      }
    )
    check t.updateBuilder(%*{"name": "John"})
      .sqlString == "UPDATE sample SET name = \"John\" JOIN t1 ON t1.c1 = sample.c1 JOIN t2 ON t2.c1 = t1.c1 WHERE c1 = \"v1\" AND c2 = \"v2\" OR or_c1 = \"or_v1\" OR or_c2 = \"or_v2\" LIMIT 5 OFFSET 3"

# =============================================================================

  test "delete":
    var t = RDB(
      query: %*{
        "table": "sample",
        "join": [
          %*{"table": "t1", "column1": "t1.c1", "symbol": "=", "column2": "sample.c1"},
          %*{"table": "t2", "column1": "t2.c1", "symbol": "=", "column2": "t1.c1"}
        ],
        "where": [
          %*{"column": "c1", "symbol": "=", "value": "v1"},
          %*{"column": "c2", "symbol": "=", "value": "v2"}
        ],
        "or_where": [
          %*{"column": "or_c1", "symbol": "=", "value": "or_v1"},
          %*{"column": "or_c2", "symbol": "=", "value": "or_v2"}
        ],
        "limit": 5,
        "offset": 3
      }
    )
    check t.deleteBuilder().sqlString == "DELETE FROM sample JOIN t1 ON t1.c1 = sample.c1 JOIN t2 ON t2.c1 = t1.c1 WHERE c1 = \"v1\" AND c2 = \"v2\" OR or_c1 = \"or_v1\" OR or_c2 = \"or_v2\" LIMIT 5 OFFSET 3"

  test "delete by id":
    var t = RDB(
      query: %*{
        "table": "sample"
      }
    )
    check t.deleteByIdBuilder(3, key="id").sqlString == "DELETE FROM sample WHERE id = 3"
