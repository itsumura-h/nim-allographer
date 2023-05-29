import times, asyncdispatch
import ../../../error
import ../database_types
import ./mariadb_rdb
import ./mariadb_lib


proc dbopen*(database: string = "", user: string = "", password: string = "", host: string = "", port: int32 = 0, maxConnections: int = 1, timeout=30): Connections =
  var pools = newSeq[Pool](maxConnections)
  for i in 0..<maxConnections:
    var res = mariadb_rdb.init(nil)
    if res == nil:
      dbError("could not open database connection")
    if mariadb_rdb.realConnect(res, host, user, password, database, port, nil, 0) == nil:
      var errmsg = $mariadb_rdb.error(res)
      mariadb_rdb.close(res)
      dbError(errmsg)
    pools[i] = Pool(
      mariadbConn: res,
      isBusy: false,
      createdAt: getTime().toUnix(),
    )
  result = Connections(
    pools: pools,
    timeout: timeout
  )

proc query*(db:PMySQL, query: string, args: seq[string], timeout:int):Future[(seq[database_types.Row], DbRows)] {.async.} =
  assert db.ping == 0
  var dbRows: DbRows
  var rows = newSeq[seq[string]]()
  var lines = 0

  rawExec(db, query, args)
  var sqlres = mariadb_rdb.useResult(db)
  let calledAt = getTime().toUnix()
  var dbColumns: DbColumns
  let cols = int(mariadb_rdb.numFields(sqlres))
  while true:
    if getTime().toUnix() >= calledAt + timeout:
      return
    await sleepAsync(0)
    var row: mariadb_rdb.Row
    var baseRow = newSeq[string](cols)
    setColumnInfo(dbColumns, sqlres, cols)
    row = mariadb_rdb.fetchRow(sqlres)
    if row == nil: break
    for i in 0..<cols:
      if row[i].isNil:
        dbColumns[i].typ.kind = dbNull
      baseRow[i] = $row[i]
    rows.add(baseRow)
    dbRows.add(dbColumns)
    lines.inc()
  free_result(sqlres)
  return (rows, dbRows)

proc queryPlain*(db:PMySQL, query: string, args: seq[string], timeout:int):Future[seq[database_types.Row]] {.async.} =
  assert db.ping == 0
  rawExec(db, query, args)
  var rows = newSeq[seq[string]]()
  var sqlres = mariadb_rdb.useResult(db)
  let calledAt = getTime().toUnix()
  let cols = int(mariadb_rdb.numFields(sqlres))
  while true:
    if getTime().toUnix() >= calledAt + timeout:
      return
    await sleepAsync(0)
    var row: mariadb_rdb.Row
    var baseRow = newSeq[string](cols)
    row = mariadb_rdb.fetchRow(sqlres)
    if row == nil: break
    for i in 0..<cols:
      baseRow[i] = $row[i]
    rows.add(baseRow)
  free_result(sqlres)
  return rows

proc exec*(db:PMySQL, query: string, args: seq[string], timeout:int) {.async.} =
  var q = dbFormat(query, args)
  await sleepAsync(0)
  if realQuery(db, q.cstring, q.len) != 0'i32: dbError(db)
