import std/asyncdispatch
import std/mysql
import ../../src/allographer/connection
import ../../src/allographer/query_builder

let rdb = dbOpen(MariaDB, "database", "user", "pass", "mariadb", 3306, shouldDisplayLog=true)
echo rdb.pools.len


var query = """
  CREATE TABLE IF NOT EXISTS `test` (
    id int
  )
"""
rdb.raw(query).exec().waitFor
