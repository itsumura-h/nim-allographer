import unittest, json

import ../src/allographer/schema_builder
import ../src/allographer/query_builder

suite "exec":
  setup:
    Schema().create([
      Table().create("testDB", [
        Column().increments("id"),
        Column().string("name"),
        Column().string("null").nullable()
      ], isRebuild=true)
    ])
    RDB().table("testDB").insert(%*{"name": "John"}).exec()
  test "get":
    var t = RDB(
      query: %*{
        "table": "testDB"
      }
    )
    check t.get() == @[%*{"id":1, "name":"John", "null":newJNull()}]

  test "get raw":
    var t = RDB(
      sqlStringSeq: @["SELECT * FROM testDB"]
    )
    check t.getRaw() == @[%*{"id":1, "name":"John", "null":newJNull()}]

  test "first":
    var t = RDB(
      query: %*{
        "table": "testDB"
      }
    )
    check t.first() == %*{"id":1, "name":"John", "null":newJNull()}
  test "find":
    var t = RDB(
      query: %*{
        "table": "testDB"
      }
    )
    check t.find(1) == %*{"id":1, "name":"John", "null":newJNull()}

# =============================================================================

  test "insert":
    var t = RDB().table("sample").insert(%*{"age": 32})
    check t.sqlStringSeq == @["INSERT INTO sample (age) VALUES (32)"]

  test "insert multi":
    var t = RDB().table("sample").insert([%*{"name": "John"}, %*{"name": "Paul"}])
    check t.sqlStringSeq == @["INSERT INTO sample (name) VALUES (\"John\"), (\"Paul\")"]
