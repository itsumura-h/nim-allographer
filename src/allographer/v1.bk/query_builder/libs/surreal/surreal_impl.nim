import std/asyncdispatch
import std/httpclient
import std/strformat
import std/strutils
import std/json
import ../../error
import ./surreal_rdb
import ./surreal_lib


proc query*(db:SurrealConn, query: string, args: seq[string], timeout:int):Future[JsonNode] {.async.} =
  ## return JArray
  assert(not db.client.isNil, "Database not connected.")
  let query = dbFormat(query, args)
  let resp = db.client.post(&"{db.host}:{db.port}/sql", query).await
  let body = resp.body().await.parseJson()
  if body.kind == JObject and body["code"].getInt() == 400:
    dbError(body["information"].getStr())
  if body[^1].hasKey("detail") and not body[^1].hasKey("result"):
    dbError(body[^1]["detail"].getStr())
  return body[^1]["result"]


proc query*(db:SurrealConn, query: string, args: JsonNode, timeout:int):Future[JsonNode] {.async.} =
  ## return JArray
  assert(not db.client.isNil, "Database not connected.")
  let query = dbFormat(query, args)
  let resp = db.client.post(&"{db.host}:{db.port}/sql", query).await
  let body = resp.body().await.parseJson()
  if body.kind == JObject and body["code"].getInt() == 400:
    dbError(body["information"].getStr())
  if body[^1].hasKey("detail") and not body[^1].hasKey("result"):
    dbError(body[^1]["detail"].getStr())
  return body[^1]["result"]


proc exec*(db:SurrealConn, query: string, args: seq[string], timeout:int) {.async.} =
  assert(not db.client.isNil, "Database not connected.")
  let query = dbFormat(query, args)
  let resp = db.client.post(&"{db.host}:{db.port}/sql", query).await
  let body = resp.body().await.parseJson()
  if body.kind == JObject and body["code"].getInt() == 400:
    dbError(body["information"].getStr())
  if body.kind == JArray:
    for row in body:
      if row.kind == JObject:
        if row["status"].getStr() == "ERR":
          dbError(row["detail"].getStr())


proc exec*(db:SurrealConn, query: string, args: JsonNode, timeout:int) {.async.} =
  assert(not db.client.isNil, "Database not connected.")
  let query = dbFormat(query, args)
  let resp = db.client.post(&"{db.host}:{db.port}/sql", query).await
  let body = resp.body().await.parseJson()
  if body.kind == JObject and body["code"].getInt() == 400:
    dbError(body["information"].getStr())
  if body.kind == JArray:
    for row in body:
      if row.kind == JObject:
        if row["status"].getStr() == "ERR":
          dbError(row["detail"].getStr())


proc info*(db:SurrealConn, query: string, args: seq[string], timeout:int):Future[JsonNode] {.async.} =
  assert(not db.client.isNil, "Database not connected.")
  let query = dbFormat(query, args)
  let resp = db.client.post(&"{db.host}:{db.port}/sql", query).await
  return resp.body().await.parseJson()


proc info*(db:SurrealConn, query: string, args: JsonNode, timeout:int):Future[JsonNode] {.async.} =
  assert(not db.client.isNil, "Database not connected.")
  let query = dbFormat(query, args)
  let resp = db.client.post(&"{db.host}:{db.port}/sql", query).await
  return resp.body().await.parseJson()
