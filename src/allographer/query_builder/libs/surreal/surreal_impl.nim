import std/asyncdispatch
import std/httpclient
import std/strformat
import std/strutils
import std/json
import ../../error
import ./surreal_rdb
import ./surreal_lib

type SurrealImpl* = ref object


proc surrealTimeoutMs(timeout: int): int =
  if timeout <= 0:
    return 0
  if timeout > high(int) div 1000:
    return high(int)
  result = timeout * 1000


proc awaitWithTimeout[T](fut: Future[T], timeoutMs: int, timeoutMsg: string): Future[T] {.async.} =
  if timeoutMs <= 0:
    return await fut

  let ok = await withTimeout(fut, timeoutMs)
  if not ok:
    dbError(timeoutMsg)
  result = fut.read


proc failSurrealBody(body: JsonNode) =
  if body.kind == JObject:
    if body.hasKey("code") and body["code"].kind == JInt and body["code"].getInt == 400:
      if body.hasKey("information") and body["information"].kind == JString:
        dbError(body["information"].getStr())
    if body.hasKey("detail") and not body.hasKey("result") and body["detail"].kind == JString:
      dbError(body["detail"].getStr())

  if body.kind == JArray:
    for row in body.items:
      if row.kind != JObject:
        continue
      if row.hasKey("status") and row["status"].kind == JString and row["status"].getStr() == "ERR":
        if row.hasKey("detail") and row["detail"].kind == JString:
          dbError(row["detail"].getStr())
      if row.hasKey("detail") and not row.hasKey("result") and row["detail"].kind == JString:
        dbError(row["detail"].getStr())


proc runSurrealSql(db: SurrealConn, sql: string, timeout: int): Future[JsonNode] {.async.} =
  let timeoutMs = surrealTimeoutMs(timeout)
  let url = &"{db.host}:{db.port}/sql"
  let response = await awaitWithTimeout(
    db.client.post(url, sql),
    timeoutMs,
    &"SurrealDb request timed out after {timeoutMs} ms"
  )
  
  let bodyText = await awaitWithTimeout(response.body(), timeoutMs,
    &"SurrealDb response body timed out after {timeoutMs} ms")

  var body: JsonNode
  try:
    body = bodyText.parseJson()
  except CatchableError:
    dbError(&"SurrealDb returned non-JSON response: {bodyText}")

  failSurrealBody(body)
  if response.status != $Http200:
    dbError(&"SurrealDb request failed with HTTP status {response.status}")

  return body

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
  let body = await runSurrealSql(db, dbFormat(query, args), timeout)
  if body.kind != JArray or body.len == 0:
    dbError("SurrealDb returned empty result set")
  return body[^1]["result"]


proc query*(db:SurrealConn, query: string, args: JsonNode, timeout:int):Future[JsonNode] {.async.} =
  ## return JArray
  assert(not db.client.isNil, "Database not connected.")
  let body = await runSurrealSql(db, dbFormat(query, args), timeout)
  if body.kind != JArray or body.len == 0:
    dbError("SurrealDb returned empty result set")
  return body[^1]["result"]


proc exec*(db:SurrealConn, query: string, args: seq[string], timeout:int) {.async.} =
  assert(not db.client.isNil, "Database not connected.")
  let body = await runSurrealSql(db, dbFormat(query, args), timeout)
  if body[^1]["status"].getStr() == "ERR":
    dbError(body[^1]["result"].getStr())


proc exec*(db:SurrealConn, query: string, args: JsonNode, timeout:int) {.async.} =
  assert(not db.client.isNil, "Database not connected.")
  let body = await runSurrealSql(db, dbFormat(query, args), timeout)
  if body[^1]["status"].getStr() == "ERR":
    dbError(body[^1]["result"].getStr())


proc info*(db:SurrealConn, query: string, args: seq[string], timeout:int):Future[JsonNode] {.async.} =
  assert(not db.client.isNil, "Database not connected.")
  return await runSurrealSql(db, dbFormat(query, args), timeout)


proc info*(db:SurrealConn, query: string, args: JsonNode, timeout:int):Future[JsonNode] {.async.} =
  assert(not db.client.isNil, "Database not connected.")
  return await runSurrealSql(db, dbFormat(query, args), timeout)
