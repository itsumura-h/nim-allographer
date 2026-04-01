discard """
  cmd: "nim c -d:reset -d:ssl -r $file"
"""

import std/[asyncdispatch, os, strutils, unittest]
import ../../src/allographer/connection
import ../../src/allographer/query_builder


suite "SQLite pool waiter (notify)":
  test "pool size 1: two concurrent raw gets both complete":
    let sqliteHost = getEnv("SQLITE_HOST")
    let timeout = getEnv("DB_TIMEOUT").parseInt
    let rdb = dbOpen(SQLite3, sqliteHost, maxConnections = 1, timeout)
    proc sel(): Future[void] {.async.} =
      discard await rdb.raw("SELECT 1").get()
    let a = sel()
    let b = sel()
    waitFor all(a, b)

  test "pool size 0: raw get raises DbError":
    let sqliteHost = getEnv("SQLITE_HOST")
    let rdb = dbOpen(SQLite3, sqliteHost, maxConnections = 0, timeout = 0)
    expect(DbError):
      discard waitFor rdb.raw("SELECT 1").get()
