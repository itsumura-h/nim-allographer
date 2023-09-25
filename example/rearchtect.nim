import std/asyncdispatch
import std/json
import std/httpclient
import std/streams
import std/options
import ../src/allographer/connection
import ../src/allographer/query_builder


proc main() {.async.} =
  let client = newAsyncHttpClient()
  let response = client.getContent("https://nim-lang.org/assets/img/twitter_banner.png").await
  let imageStream = newStringStream(response)
  let binaryImage = imageStream.readAll()


  let rdb = dbOpen(SQLite3, "/root/project/db.sqlite3", shouldDisplayLog=true)
  echo rdb.type

  rdb.raw("DROP TABLE IF EXISTS \"test\"").exec().await

  rdb.raw("""
    CREATE TABLE IF NOT EXISTS "test" (
      'id' INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
      'blob' BLOB,
      'int' INTEGER,
      'float' NUMERIC,
      'str' VARCHAR
    )"""
  ).exec().await

  rdb.table("test").insert(%*{"blob":binaryImage, "int": 1, "float": 1.1, "str": "alice"}).await

  let res = rdb.table("test").select("id", "int", "float", "str").get().await
  for row in res:
    echo row

  var row = rdb.table("test").select("id", "int", "float", "str").first().await
  if row.isSome:
    echo row.get

  rdb.table("test").where("id", "=", 1).update(%*{"str": "bob"}).await

  row = rdb.table("test").select("id", "int", "float", "str").find(1).await
  if row.isSome:
    echo row.get

main().waitFor
