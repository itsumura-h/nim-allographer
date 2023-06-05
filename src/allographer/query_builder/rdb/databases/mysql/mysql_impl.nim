import asyncdispatch, strutils, times
import ../../../error
import ../database_types
import ./mysql_rdb
import ./mysql_lib

# https://dev.mysql.com/doc/c-api/8.0/en/c-api-asynchronous-interface-usage.html

proc dbopen*(database: string = "", user: string = "", password: string = "", host: string = "", port: int32 = 0, maxConnections: int = 1, timeout=30): Connections =
  var pools = newSeq[Pool](maxConnections)
  for i in 0..<maxConnections:
    var mysql = mysql_rdb.init(nil)
    if mysql == nil:
      dbError("could not open database connection")
    var status = real_connect_nonblocking(mysql, host, user, password, database, port, nil, 0)
    while status == NET_ASYNC_NOT_READY:
      status = real_connect_nonblocking(mysql, host, user, password, database, port, nil, 0)
    if status == NET_ASYNC_ERROR:
      dbError("mysql_real_connect_nonblocking() failed")
    pools[i] = Pool(
      mysqlConn: mysql,
      isBusy: false,
      createdAt: getTime().toUnix(),
    )
  result = Connections(
    pools: pools,
    timeout: timeout
  )

proc query*(db: PMySQL, query: string, args: seq[string], timeout:int):Future[(seq[database_types.Row], DbRows)] {.async.} =
  assert db.ping == 0
  let query = dbFormat(query, args)
  var status = real_query_nonblocking(db, query.cstring, query.len)
  while status == NET_ASYNC_NOT_READY:
    await sleepAsync(0)
    status = real_query_nonblocking(db, query.cstring, query.len)
  if status == NET_ASYNC_ERROR: dbError(db) # failed
  var res: PRES
  status = store_result_nonblocking(db, res.addr)
  while status == NET_ASYNC_NOT_READY:
    await sleepAsync(0)
    status = store_result_nonblocking(db, res.addr)
  if status == NET_ASYNC_ERROR: dbError(db)
  if res == nil: dbError(db)
  let cols = num_fields(res)
  var rows = newSeq[database_types.Row]()
  let calledAt = getTime().toUnix()
  var dbRows: DbRows
  var lines = 0
  while true:
    if getTime().toUnix() >= calledAt + timeout:
      return
    await sleepAsync(0)
    var row: mysql_rdb.Row
    status = fetch_row_nonblocking(res, row.addr)
    while status != NET_ASYNC_COMPLETE:
      await sleepAsync(0)
      status = fetch_row_nonblocking(res, row.addr)
    if row == nil: break
    var baseRow = newSeq[string](cols)
    setColumnInfo(res, dbRows, lines, cols)
    for i in 0..<cols:
      if row[i].isNil:
        dbRows[lines][i].typ.kind = dbNull
      baseRow[i] = $row[i]
    rows.add(baseRow)
    lines.inc()
  free_result(res)
  return (rows, dbRows)

proc queryPlain*(db: PMySQL, query: string, args: seq[string], timeout:int):Future[seq[database_types.Row]] {.async.} =
  assert db.ping == 0
  let query = dbFormat(query, args)
  var status = real_query_nonblocking(db, query.cstring, query.len)
  while status == NET_ASYNC_NOT_READY:
    await sleepAsync(0)
    status = real_query_nonblocking(db, query.cstring, query.len)
  if status == NET_ASYNC_ERROR: dbError(db) # failed
  var res: PRES
  status = store_result_nonblocking(db, res.addr)
  while status == NET_ASYNC_NOT_READY:
    await sleepAsync(0)
    status = store_result_nonblocking(db, res.addr)
  if status == NET_ASYNC_ERROR: dbError(db)
  if res == nil: dbError(db)
  let cols = num_fields(res)
  var rows = newSeq[database_types.Row]()
  let calledAt = getTime().toUnix()
  var lines = 0
  while true:
    if getTime().toUnix() >= calledAt + timeout:
      dbError(db)
    await sleepAsync(0)
    var row: mysql_rdb.Row
    status = fetch_row_nonblocking(res, row.addr)
    while status != NET_ASYNC_COMPLETE:
      await sleepAsync(0)
      status = fetch_row_nonblocking(res, row.addr)
    if row == nil: break
    rows.add(row.cstringArrayToSeq(cols))
    lines.inc()
  free_result(res)
  return rows

proc exec*(db:PMySQL, query: string, args: seq[string], timeout:int) {.async.} =
  assert db.ping == 0
  let query = dbFormat(query, args)
  var status = real_query_nonblocking(db, query.cstring, query.len)
  while status == NET_ASYNC_NOT_READY:
    await sleepAsync(0)
    status = real_query_nonblocking(db, query.cstring, query.len)
  if status == NET_ASYNC_ERROR: dbError(db) # failed
