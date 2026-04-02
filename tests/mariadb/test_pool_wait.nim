discard """
  cmd: "nim c -d:ssl -r $file"
"""
# nim c -d:ssl r tests/mariadb/test_pool_wait.nim

import std/[asyncdispatch, deques, os, strutils, unittest]
import ../../src/allographer/connection
import ../../src/allographer/query_builder


suite "MariaDB pool waiter (notify)":
  test "pool size 1: two concurrent raw gets both complete":
    let mariaUrl = getEnv("MARIA_URL")
    let timeout = getEnv("DB_TIMEOUT").parseInt
    let rdb = dbOpen(MariaDB, mariaUrl, maxConnections = 1, timeout)

    proc sel(): Future[void] {.async.} =
      discard await rdb.raw("SELECT SLEEP(0.05), 1").get()

    let a = sel()
    let b = sel()
    waitFor all(a, b)
    check rdb.pools.waiters.len == 0

  test "pool size 0: raw get raises DbError":
    let mariaUrl = getEnv("MARIA_URL")
    let rdb = dbOpen(MariaDB, mariaUrl, maxConnections = 0, timeout = 0)
    expect(DbError):
      discard waitFor rdb.raw("SELECT 1").get()
