discard """
  cmd: "nim c $file"
"""

import std/os
import std/unittest
import ../../src/allographer/connection


suite("SQLite connection"):
  test("connection"):
    let database = getTempDir() / "allographer-open-test.sqlite3"
    let rdb = dbOpen(SQLite3, database, shouldDisplayLog=false)
    check(rdb.pools.conns.len > 0)


  test("connection with DatabaseUrl"):
    let database = getTempDir() / "allographer-open-test-url.sqlite3"
    let url = asDatabaseUrl("sqlite:///" & database)
    let rdb = dbOpen(SQLite3, databaseUrl = url)
    check(rdb.pools.conns.len > 0)
