import times, asyncdispatch
import ../base
import ../rdb/mariadb
import ../libs/lib_mariadb


proc dbopen*(database: string = "", user: string = "", password: string = "", host: string = "", port: int32 = 0, maxConnections: int = 1, timeout=30): Connections =
  var pools = newSeq[Pool](maxConnections)
  for i in 0..<maxConnections:
    var res = mariadb.init(nil)
    if res == nil:
      dbError("could not open database connection")
    if mariadb.realConnect(res, host, user, password, database, port, nil, 0) == nil:
      var errmsg = $mariadb.error(res)
      mariadb.close(res)
      dbError(errmsg)
    pools[i] = Pool(
      mariadbConn: res,
      isBusy: false,
      createdAt: getTime().toUnix(),
    )
  result = Connections(
    driver: Driver.MariaDB,
    pools: pools,
    timeout: timeout
  )

proc query*(db:PMySQL, query: string, args: seq[string], timeout:int):Future[seq[base.Row]] {.async.} =
  assert db.ping == 0
  let query = dbFormat(query, args)
  var status = real_query_nonblocking(db, query, query.len)
  while status == NET_ASYNC_NOT_READY:
    await sleepAsync(0)
    status = real_query_nonblocking(db, query, query.len)
  if status == NET_ASYNC_ERROR: dbError(db) # failed
  var res: PRES
  status = store_result_nonblocking(db, res.addr)
  while status == NET_ASYNC_NOT_READY:
    await sleepAsync(0)
    status = store_result_nonblocking(db, res.addr)
  if status == NET_ASYNC_ERROR: dbError(db)
  if res == nil: dbError(db)
  let L = num_fields(res)
  var rows = newSeq[base.Row]()
  let calledAt = getTime().toUnix()
  while true:
    if getTime().toUnix() >= calledAt + timeout:
      dbError(db)
    await sleepAsync(0)
    var row: mariadb.Row
    status = fetch_row_nonblocking(res, row.addr)
    while status != NET_ASYNC_COMPLETE:
      await sleepAsync(0)
      status = fetch_row_nonblocking(res, row.addr)
    if row == nil: break
    var baseRow = newSeq[string](L)
    for i in 0..<L:
      baseRow[i] = $row[i]
    rows.add(baseRow)
  var dbColumns: DbColumns
  setColumnInfo(dbColumns, res, L)
  return rows

proc exec*(db:PMySQL, query: string, args: seq[string], timeout:int) {.async.} =
  var q = dbFormat(query, args)
  await sleepAsync(0)
  if realQuery(db, q, q.len) != 0'i32: dbError(db)
