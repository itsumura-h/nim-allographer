discard """
  cmd: "nim c -d:reset -r $file"
"""

import std/unittest
import std/asyncdispatch
import std/json
import ../src/allographer/connection
import ../src/allographer/query_builder

suite("surreal"):
  var surreal:SurrealDb

  test("connection"):
    surreal = dbOpen(SurrealDb, "test", "test", "user", "pass", "http://surreal", 8000, 10, 30, true, false).waitFor()

  test("insert data"):
    waitFor surreal.raw("""INSERT INTO user (name, email) VALUES ("alice", "alice@exmaple.com")""").exec()

  test("raw query"):
    let res = waitFor surreal.raw("SELECT * FROM user").get()
    echo res.pretty()
