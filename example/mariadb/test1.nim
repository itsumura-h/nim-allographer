import std/asyncdispatch
import std/mysql
import std/db_mysql
import std/json
import ../../src/allographer/connection
import ../../src/allographer/query_builder

let rdb = dbOpen(MariaDB, "database", "user", "pass", "mariadb", 3306, shouldDisplayLog=true)
echo rdb.pools.len


rdb.raw("""
  DROP TABLE IF EXISTS `test`
""").exec().waitFor

rdb.raw("""
  CREATE TABLE IF NOT EXISTS `test` (
    id int,
    str varchar(256)
  )
""").exec().waitFor

rdb.raw("""
  INSERT INTO `test` (id, str) VALUES (?, ?)
""", %*[1, "alice"]).exec().waitFor

# rdb.raw("""
#   INSERT INTO `test` VALUES (1)
# """).exec().waitFor
