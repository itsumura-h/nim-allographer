discard """
  cmd: "nim c $file"
"""

# nim c -r tests/v2/mariadb/test_open.nim

import std/unittest
import ../../src/allographer/connection
import ../../src/allographer/query_builder


suite("MariaDB connection"):
  test("connection"):
    let database = "database"
    let user = "user"
    let password = "pass"
    let host = "mariadb"
    let port = 3306
    
    let rdb = dbOpen(Mariadb, database, user, password, host, port)
    check(rdb.isConnected())


  test("connection with URL"):
    let url = "mariadb://user:pass@mariadb:3306/database"
    let rdb = dbOpen(Mariadb, url)
    check(rdb.isConnected())


  test("url is not start with mariadb://"):
    let url = "aaa://user:pass@mariadb:3306/database"
    expect(ValueError):
      discard dbOpen(Mariadb, url)


  test("cannot reach to database"):
    let url = "mariadb://john:password@host:0001/database"
    expect(DbError):
      discard dbOpen(Mariadb, url)
