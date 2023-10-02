import std/asyncdispatch
import std/httpclient
import std/httpcore
import std/strformat
import std/base64
import std/times
import ../../libs/surreal/surreal_rdb
import ../../error
import ../../log
import ./surreal_types


proc dbOpen*(_:type SurrealDB, namespace:string = "", database: string = "", user: string = "", password: string = "",
              host: string = "", port: int32 = 0, maxConnections: int = 1, timeout=30,
              shouldDisplayLog=false, shouldOutputLogFile=false, logDir=""): Future[SurrealConnections] {.async.} =
  var pools = newSeq[SurrealConnection](maxConnections)
  for i in 0..<maxConnections:
    let client = newAsyncHttpClient()
    var headers = newHttpHeaders(true)
    headers["NS"] = namespace
    headers["DB"] = database
    headers["Accept"] = "application/json"
    headers["Authorization"] = "Basic " & base64.encode(user & ":" & password)
    client.headers = headers

    var url = &"{host}:{port}/status"
    var resp = client.get(url).await
    if(resp.status != $Http200):
      dbError(&"Cannot connect to SurrealDb {host}:{port}")

    url = &"{host}:{port}/sql"
    resp = client.post(url, &"DEFINE NAMESPACE `{namespace}`; USE NS `{namespace}`; DEFINE DATABASE `{database}`").await
    if(resp.status != $Http200):
      dbError(&"Cannot connect to SurrealDb {host}:{port}")

    let conn = SurrealConn(
      client: client,
      host: host,
      port: port
    )

    pools[i] = SurrealConnection(
      conn: conn,
      isBusy: false,
      createdAt: getTime().toUnix(),
    )

  return SurrealConnections(
    pools: pools,
    timeout: timeout,
    log: LogSetting(shouldDisplayLog:shouldDisplayLog, shouldOutputLogFile:shouldOutputLogFile, logDir:logDir)
  )
