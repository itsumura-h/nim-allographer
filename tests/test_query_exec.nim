import unittest, json

import ../src/allographer/schema_builder
import ../src/allographer/query_builder

proc resetDB() =
  Schema().create([
    Table().create("testDB", [
      Column().increments("id"),
      Column().string("name"),
      Column().string("null").nullable()
    ], reset=true)
  ])
  RDB().table("testDB").insert(%*{"name": "John"}).exec()

proc deleteDB() =
  RDB().raw("DROP TABLE testDB").exec()

suite "exec":
  test "get":
    resetDB()
    var t = RDB(
      query: %*{
        "table": "testDB"
      }
    )
    echo "===================="
    echo t.get()
    check t.get() == @[%*{"id":1, "name":"John", "null":newJNull()}]

  test "get raw":
    resetDB()
    var t = RDB(
      sqlStringSeq: @["SELECT * FROM testDB"]
    )
    check t.getRaw() == @[%*{"id":1, "name":"John", "null":newJNull()}]

  test "first":
    resetDB()
    var t = RDB(
      query: %*{
        "table": "testDB"
      }
    )
    check t.first() == %*{"id":1, "name":"John", "null":newJNull()}

  test "find":
    resetDB()
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

  test "inserts":
    var t = RDB().table("sample").inserts([
      %*{"name": "John"},
      %*{"email": "Paul@gmail.com"}
    ])
    check t.sqlStringSeq == @[
      "INSERT INTO sample (name) VALUES (\"John\")",
      "INSERT INTO sample (email) VALUES (\"Paul@gmail.com\")"
    ]

# =============================================================================

  test "update":
    var t = RDB().table("sample").where("name", "=", "John").update(%*{"name": "Paul"})
    check t.sqlStringSeq == @[
      "UPDATE sample SET name = \"Paul\" WHERE name = \"John\""
    ]

# =============================================================================

  test "delete":
    var t = RDB().table("sample").where("name", "=", "John").delete()
    check t.sqlStringSeq == @[
      "DELETE FROM sample WHERE name = \"John\""
    ]

  test "delete id":
    var t = RDB().table("sample").delete(3)
    check t.sqlStringSeq == @[
      "DELETE FROM sample WHERE id = 3"
    ]

# =============================================================================

  test "execID insert":
    resetDB()
    var t = RDB().table("testDB").insert(%*{"name": "Paul"}).execID()
    check t == 2

test "execID":
    resetDB()
    var t = RDB().table("testDB").where("name", "=", "Paul").delete().execID()
    check t == 0

deleteDB()