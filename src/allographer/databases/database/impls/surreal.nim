import std/asyncdispatch
import std/httpclient
import std/times
import std/strformat
import std/base64
import std/strutils
import std/json
import ../database_types
import ../rdb/surreal


proc dbopen*(database: string = "", user: string = "", password: string = "", host: string = "", port: int32 = 0, maxConnections: int = 1, timeout=30): Connections =
  var pools = newSeq[Pool](maxConnections)
  for i in 0..<maxConnections:
    let client = newAsyncHttpClient()
    var headers = newHttpHeaders(true)
    headers["NS"] = database.split(":")[0]
    headers["DB"] = database.split(":")[1]
    headers["Accept"] = "application/json"
    headers["Authorization"] = "Basic " & base64.encode(user & ":" & password)
    client.headers = headers

    pools[i] = Pool(
      surrealConn: SurrealConn(conn: client, host:host, port:port),
      isBusy: false,
      createdAt: getTime().toUnix(),
    )
  result = Connections(
    pools: pools,
    timeout: timeout
  )

proc query*(db:SurrealConn, query: string, args: seq[string], timeout:int):Future[(seq[Row], DbRows)] {.async.} =
  assert(not db.conn.isNil, "Database not connected.")
  var dbRows: DbRows
  var rows = newSeq[seq[string]]()
  let resp = await db.conn.post(&"{db.host}:{db.port}/sql", query)
  let body = resp.body.await
  rows.add(
    @[$body.parseJson[0]]
  )
  return (rows, dbRows)


proc exec*(db:SurrealConn, query: string, args: seq[string], timeout:int) {.async.} =
  assert(not db.conn.isNil, "Database not connected.")
  let resp = await db.conn.post(&"{db.host}:{db.port}/sql", query)
  if resp.code != Http200:
    dbError(resp.body.await)
