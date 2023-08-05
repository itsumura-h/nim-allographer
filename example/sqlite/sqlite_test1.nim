import std/asyncdispatch
import std/httpclient
import std/streams
import std/json
import ../../src/allographer/connection
import ../../src/allographer/query_builder


proc main() {.async.} =
  let client = newAsyncHttpClient()
  let response = client.getContent("https://nim-lang.org/assets/img/twitter_banner.png").await
  let imageStream = newStringStream(response)
  let binaryImage = imageStream.readAll()

  let rdb = dbOpen(SQLite3, "/root/project/db.sqlite3", shouldDisplayLog=true)
  await rdb.raw("DROP TABLE IF EXISTS \"test\"").exec()
  await rdb.raw("""
    CREATE TABLE IF NOT EXISTS "test" (
      'id' INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
      'bool' TINYINT,
      'int' INTEGER,
      'float' NUMERIC,
      'str' VARCHAR,
      'json' VARCHAR,
      'null' VARCHAR,
      'blob' BLOB
    )
  """).exec()

  await rdb.table("test").insert(%*{
    "blob": binaryImage,
    "bool": true,
    "int": 1,
    "float": 1.1,
    "str": "alice",
    "json": {"name":"alice", "email":"alice@example.com"},
    "null": nil
  })
  echo rdb.table("test").get().await
  echo rdb.select("id", "str").table("test").get().await

  await rdb.table("test").where("id", "=", 1).update(%*{
    "blob": binaryImage,
    "bool": false,
    "int": 2,
    "float": 2.1,
    "json": {"name":"bob", "email":"bob@example.com"},
    "str": "bob",
  })
  echo rdb.table("test").get().await

  await rdb.raw(
    """
      UPDATE "test"
      SET
        `bool` = ?,
        `int` = ?,
        `float` = ?,
        `json` = ?,
        `str` = ?,
        `null` = ?
      WHERE `id` = ?
    """,
    %*[true, 3, 3.3, {"name":"charlie", "email":"charlie@example.com"}, "charlie", nil, 1]
  ).exec()
  echo rdb.raw("SELECT * FROM \"test\"").get().await


main().waitFor()
