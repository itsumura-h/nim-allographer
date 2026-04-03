import std/asyncdispatch
import std/deques
import std/httpclient
import std/httpcore
import std/strformat
import std/base64
import std/tables
import std/times
import ../../libs/surreal/surreal_rdb
import ../../error
import ../../log
import ./surreal_types


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


proc buildSurrealHeaders(namespace, database, authHeader: string): HttpHeaders =
  result = newHttpHeaders(true)
  result["Surreal-NS"] = namespace
  result["Surreal-DB"] = database
  result["Accept"] = "application/json"
  result["Authorization"] = authHeader


proc dbOpen*(_:type SurrealDB, namespace:string = "", database: string = "", user: string = "", password: string = "",
              host: string = "", port: int = 0, maxConnections: int = 1, timeout=30,
              shouldDisplayLog=false, shouldOutputLogFile=false, logDir=""): Future[SurrealConnections] {.async.} =
  let timeoutMs = surrealTimeoutMs(timeout)
  let statusUrl = &"{host}:{port}/status"
  let sqlUrl = &"{host}:{port}/sql"
  let bootstrapSql = &"USE NS `{namespace}` DB `{database}`"
  let authHeader = "Basic " & base64.encode(user & ":" & password)
  var conns = newSeq[Connection](maxConnections)
  for i in 0..<maxConnections:
    let client = newAsyncHttpClient()
    client.headers = buildSurrealHeaders(namespace, database, authHeader)

    let statusResp = await awaitWithTimeout(client.get(statusUrl), timeoutMs,
      &"Cannot connect to SurrealDb {host}:{port} (status request timed out)")
    if statusResp.status != $Http200:
      dbError(&"Cannot connect to SurrealDb {host}:{port}")

    if i == 0:
      let bootstrapResp = await awaitWithTimeout(client.post(sqlUrl, bootstrapSql), timeoutMs,
        &"Cannot connect to SurrealDb {host}:{port} (bootstrap request timed out)")
      if bootstrapResp.status != $Http200:
        dbError(&"Cannot connect to SurrealDb {host}:{port}")

    let conn = SurrealConn(
      client: client,
      host: host,
      port: port.int32
    )

    conns[i] = Connection(
      conn: conn,
      isBusy: false,
      createdAt: getTime().toUnix(),
    )
  let pools = Connections(
    conns: conns,
    timeout: timeout,
    waiters: initDeque[Future[void]](),
    preparedCache: initTable[string, SurrealPreparedEntry](),
  )
  return SurrealConnections(
    pools: pools,
    log: LogSetting(shouldDisplayLog:shouldDisplayLog, shouldOutputLogFile:shouldOutputLogFile, logDir:logDir)
  )
