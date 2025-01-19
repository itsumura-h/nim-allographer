discard """
  cmd: "nim c $file"
"""

# nim c -r tests/v2/postgres/test_open.nim

import std/unittest
import ../../src/allographer/connection
import ../../src/allographer/query_builder


suite("PostgreSQL connection"):
  test("connection"):
    let database = "database"
    let user = "user"
    let password = "pass"
    let host = "postgres"
    let port = 5432
    
    let rdb = dbOpen(PostgreSQL, database, user, password, host, port)
    check(rdb.isConnected())


  test("connection with URL"):
    let url = "postgresql://user:pass@postgres:5432/database"
    let rdb = dbOpen(PostgreSQL, url)
    check(rdb.isConnected())


  test("url is not start with postgresql://"):
    let url = "mysql://user:pass@postgres:5432/database"
    expect(ValueError):
      discard dbOpen(PostgreSQL, url)


  test("cannot reach to database"):
    let url = "postgresql://john:password@host:0001/database"
    expect(DbError):
      discard dbOpen(PostgreSQL, url)
