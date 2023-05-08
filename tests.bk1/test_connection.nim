discard """
  cmd: "nim c -d:reset -r $file"
"""

import std/asyncdispatch
import std/unittest
import ../src/allographer/connection
import ../src/allographer/databases/database_types

suite "connection":
  test "sqlite connect":
    let rdb = waitFor dbOpen(SQLite3, ":memory:", maxConnections=10, shouldDisplayLog=true)
    check not rdb.isNil

  test "surreal connect":
    let rdb = waitFor dbOpen(SurrealDB, "test:test", "user", "pass", "http://surreal", 8000, maxConnections=10, shouldDisplayLog=true)
    check not rdb.isNil

  test "surreal connect fail":
    expect DbError:
      discard waitFor dbOpen(SurrealDB, "test:test", "user", "pass", "http://surreal", 8080, maxConnections=10, shouldDisplayLog=true)
