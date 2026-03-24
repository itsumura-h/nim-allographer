discard """
  cmd: "nim c -d:reset $file"
"""

import std/[asyncdispatch, os, strutils, unittest]
import ../../src/allographer/connection
import ../../src/allographer/query_builder

proc envIntDefault(key: string, defaultValue: int): int =
  let value = getEnv(key)
  if value.len == 0:
    return defaultValue
  return value.parseInt


suite "SurrealDB pool waiter (notify)":
  test "pool size 1: two concurrent raw gets both complete":
    let timeout = envIntDefault("DB_TIMEOUT", 30)
    let rdb = dbOpen(SurrealDB, "test", "test", "user", "pass", "http://surreal", 8000,
      maxConnections = 1, timeout).waitFor()
    proc sel(): Future[void] {.async.} =
      discard await rdb.raw("RETURN 1;").get()
    let a = sel()
    let b = sel()
    waitFor all(a, b)
