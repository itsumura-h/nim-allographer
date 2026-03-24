discard """
  cmd: "nim c -d:reset $file"
"""

import std/[asyncdispatch, os, strutils, unittest]
import ../../src/allographer/connection
import ../../src/allographer/query_builder


suite "SurrealDB pool waiter (notify)":
  test "pool size 1: two concurrent raw gets both complete":
    let timeout = getEnv("DB_TIMEOUT").parseInt
    let rdb = dbOpen(SurrealDB, "test", "test", "user", "pass", "http://surreal", 8000,
      maxConnections = 1, timeout).waitFor()
    proc sel(): Future[void] {.async.} =
      discard await rdb.raw("RETURN 1;").get()
    let a = sel()
    let b = sel()
    waitFor all(a, b)
