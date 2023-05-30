import std/asyncdispatch
import std/httpclient
import std/times
import std/strformat
import std/base64
import std/strutils
import std/json
import ../../error
import ./surreal_rdb
import ./surreal_lib

type SurrealImpl* = ref object

proc open*(_:type SurrealImpl, namespace="", database="",user="", password="",
            host: string = "", port: int32 = 0,maxConnections=1,timeout=30):Future[SurrealConnections] {.async.} =
  var pools = newSeq[SurrealConn](maxConnections)
  for i in 0..<maxConnections:
    let client = newAsyncHttpClient()
    var headers = newHttpHeaders(true)
    headers["NS"] = namespace
    headers["DB"] = database
    headers["Accept"] = "application/json"
    headers["Authorization"] = "Basic " & base64.encode(user & ":" & password)
    client.headers = headers

    let url = &"{host}:{port}/status"
    let resp = client.get(url).await

    if(resp.status != $Http200):
      dbError(&"Cannot connect to SurrealDb {host}:{port}")
      break

    pools[i] = SurrealConn(
      conn: client,
      host:host,
      port:port,
      isBusy: false,
      createdAt: getTime().toUnix(),
    )
  return SurrealConnections(
    pools: pools,
    timeout: timeout
  )


proc query*(db:SurrealConn, query: string, args: seq[string], timeout:int):Future[JsonNode] {.async.} =
  ## return JArray
  assert(not db.conn.isNil, "Database not connected.")
  let query = dbFormat(query, args)
  let resp = db.conn.post(&"{db.host}:{db.port}/sql", query).await
  let body = resp.body().await.parseJson()
  if body.kind == JObject and body["code"].getInt() == 400:
    dbError(body["information"].getStr())
  return body[0]["result"]


proc exec*(db:SurrealConn, query: string, args: seq[string], timeout:int) {.async.} =
  assert(not db.conn.isNil, "Database not connected.")
  let query = dbFormat(query, args)
  let resp = db.conn.post(&"{db.host}:{db.port}/sql", query).await
  let body = resp.body().await.parseJson()
  if body.kind == JObject and body["code"].getInt() == 400:
    dbError(body["information"].getStr())
