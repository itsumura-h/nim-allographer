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

proc query*(db:PMySQL, query: string, args: seq[string], timeout:int):Future[(seq[base.Row], DbRows)] {.async.} =
  assert db.ping == 0
  var dbRows: DbRows
  var rows = newSeq[seq[string]]()
  var lines = 0

  rawExec(db, query, args)
  var sqlres = mariadb.useResult(db)
  let calledAt = getTime().toUnix()
  var dbColumns: DbColumns
  let cols = int(mariadb.numFields(sqlres))
  while true:
    if getTime().toUnix() >= calledAt + timeout:
      return
    await sleepAsync(0)
    var row: mariadb.Row
    var baseRow = newSeq[string](cols)
    setColumnInfo(dbColumns, sqlres, cols)
    row = mariadb.fetchRow(sqlres)
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

proc queryPlain*(db:PMySQL, query: string, args: seq[string], timeout:int):Future[seq[base.Row]] {.async.} =
  assert db.ping == 0
  var dbRows: DbRows
  var rows = newSeq[seq[string]]()
  var lines = 0

  rawExec(db, query, args)
  var sqlres = mariadb.useResult(db)
  let calledAt = getTime().toUnix()
  let cols = int(mariadb.numFields(sqlres))
  while true:
    if getTime().toUnix() >= calledAt + timeout:
      return
    await sleepAsync(0)
    var row: mariadb.Row
    var baseRow = newSeq[string](cols)
    row = mariadb.fetchRow(sqlres)
    if row == nil: break
    for i in 0..<cols:
      baseRow[i] = $row[i]
    rows.add(baseRow)
    lines.inc()
  free_result(sqlres)
  return rows

proc exec*(db:PMySQL, query: string, args: seq[string], timeout:int) {.async.} =
  var q = dbFormat(query, args)
  await sleepAsync(0)
  if realQuery(db, q, q.len) != 0'i32: dbError(db)
