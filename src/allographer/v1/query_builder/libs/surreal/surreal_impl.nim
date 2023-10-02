import std/asyncdispatch
import std/httpclient
import std/strformat
import std/strutils
import std/json
import ../../error
import ./surreal_rdb
import ./surreal_lib

type SurrealImpl* = ref object

# proc open*(_:type SurrealImpl, namespace="", database="",user="", password="",
#             host="", port:int32 = 0, maxConnections=1, timeout=30):Future[SurrealConnections] {.async.} =
#   var pools = newSeq[SurrealConn](maxConnections)
#   for i in 0..<maxConnections:
#     let client = newAsyncHttpClient()
#     var headers = newHttpHeaders(true)
#     headers["NS"] = namespace
#     headers["DB"] = database
#     headers["Accept"] = "application/json"
#     headers["Authorization"] = "Basic " & base64.encode(user & ":" & password)
#     client.headers = headers

#     var url = &"{host}:{port}/status"
#     var resp = client.get(url).await
#     if(resp.status != $Http200):
#       dbError(&"Cannot connect to SurrealDb {host}:{port}")

#     url = &"{host}:{port}/sql"
#     resp = client.post(url, &"DEFINE NAMESPACE `{namespace}`; USE NS `{namespace}`; DEFINE DATABASE `{database}`").await
#     if(resp.status != $Http200):
#       dbError(&"Cannot connect to SurrealDb {host}:{port}")

#     pools[i] = SurrealConn(
#       conn: client,
#       host:host,
#       port:port,
#       isBusy: false,
#       createdAt: getTime().toUnix(),
#     )
#   return SurrealConnections(
#     pools: pools,
#     timeout: timeout
#   )


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
