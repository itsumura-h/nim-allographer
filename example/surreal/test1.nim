import std/asyncdispatch
import std/httpclient
import std/streams
import std/json
import ../../src/allographer/connection
import ../../src/allographer/query_builder
import ../../src/allographer/schema_builder

proc main() {.async.} =
  let rdb = dbOpen(SurrealDB, "ns", "database", "user", "pass", "http://surreal", 8000, shouldDisplayLog=true).await
  
  rdb.raw("""
    REMOVE TABLE `test`
  """).exec().await

  rdb.raw("""
    DEFINE TABLE `test` SCHEMAFULL;
    DEFINE FIELD `bool` ON TABLE `test` TYPE bool;
    DEFINE FIELD `int` ON TABLE `test` TYPE int;
    DEFINE FIELD `float` ON TABLE `test` TYPE decimal;
    DEFINE FIELD `str` ON TABLE `test` TYPE string;
    DEFINE FIELD `data` ON TABLE `test` TYPE string;
    DEFINE FIELD `object` ON TABLE `test` FLEXIBLE TYPE object;
  """).exec().waitFor

  echo rdb.table("test").columns().waitFor

  rdb.raw("""
    INSERT INTO `test` {bool:?, int:?, float:?, str:?, object:?}
  """, %*[true, 1, 1.1, "alice", {"bool": false, "int": 2, "float": 2.1, "str": "two"}]).exec().waitFor

  echo rdb.raw("""
    SELECT * FROM `test`
  """).get().waitFor

  let client = newAsyncHttpClient()
  var veryLongText = ""
  var response = client.getContent("https://bible-api.com/genesis+1:1-31").await.parseJson
  veryLongText.add(response["text"].getStr)
  response = client.getContent("https://bible-api.com/genesis+2:1-25").await.parseJson
  veryLongText.add(response["text"].getStr)
  response = client.getContent("https://bible-api.com/genesis+3:1-24").await.parseJson
  veryLongText.add(response["text"].getStr)

  rdb.table("test").insert(%*{"bool":false, "int":2, "float":2.1, "str": veryLongText}).waitFor

  echo rdb.select("bool", "int", "float", "str").table("test").get().waitFor

main().waitFor
