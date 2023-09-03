import std/asyncdispatch
import std/httpclient
import std/streams
import std/mysql
import std/db_mysql
import std/json
import ../../src/allographer/connection
import ../../src/allographer/query_builder

let rdb = dbOpen(MariaDB, "database", "user", "pass", "mariadb", 3306, shouldDisplayLog=true)
echo rdb.pools.len
# echo "rdb.pools[0].conn.repr: ",rdb.pools[0].conn.repr


proc main() {.async.} =
  rdb.raw("""
    DROP TABLE IF EXISTS `test`
  """).exec().waitFor

  rdb.raw("""
    CREATE TABLE IF NOT EXISTS `test` (
      `bool` BOOLEAN,
      `int` INT,
      `float` DOUBLE,
      `str` VARCHAR(255),
      `data` BLOB
    )
  """).exec().waitFor

  let client = newAsyncHttpClient()
  let response = client.getContent("https://nim-lang.org/assets/img/twitter_banner.png").await
  let imageStream = newStringStream(response)
  let binaryImage = imageStream.readAll()

  rdb.raw("""
    INSERT INTO `test` (`bool`, `int`, `float`, `str`) VALUES (?, ?, ?, ?)
  """, %*[true, 1, 1.1, "alice"]).exec().waitFor

  rdb.table("test").insert(%*{"bool":false, "int":2, "float":2.1, "str": "bob", "data": binaryImage}).waitFor


main().waitFor
