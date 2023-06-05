import std/asyncdispatch
import std/times
import std/strutils
import ../database_types
import ./sqlite_rdb
import ./sqlite_lib


proc dbopen*(database: string = "", user: string = "", password: string = "", host: string = "", port: int32 = 0, maxConnections: int = 1, timeout=30): Connections =
  var pools = newSeq[Pool](maxConnections)
  for i in 0..<maxConnections:
    var db: PSqlite3
    discard sqlite_rdb.open(database, db)
    pools[i] = Pool(
      sqliteConn: db,
      isBusy: false,
      createdAt: getTime().toUnix(),
    )
  result = Connections(
    pools: pools,
    timeout: timeout
  )

proc query*(db:PSqlite3, query:string, args:seq[string], timeout:int):Future[(seq[Row], DbRows)] {.async.} =
  assert(not db.isNil, "Database not connected.")
  var dbRows: DbRows
  var rows = newSeq[seq[string]]()
  for row in db.instantRows(dbRows, query, args):
    var columns = newSeq[string](row.len)
    for i in 0..row.len()-1:
      columns[i] = row[i]
    rows.add(columns)
  return (rows, dbRows)

proc queryPlain*(db:PSqlite3, query:string, args:seq[string], timeout:int):Future[seq[Row]] {.async.} =
  assert(not db.isNil, "Database not connected.")
  var rows = newSeq[seq[string]]()
  for row in db.instantRowsPlain(query, args):
    var columns = newSeq[string](row.len)
    for i in 0..row.len()-1:
      columns[i] = row[i]
    rows.add(columns)
  return rows

proc exec*(db:PSqlite3, query: string, args: seq[string], timeout:int) {.async.} =
  assert(not db.isNil, "Database not connected.")
  var q = dbFormat(query, args)
  var stmt: PStmt
  var res:bool
  if prepare_v2(db, q.cstring, q.len.cint, stmt, nil) == SQLITE_OK:
    let x = step(stmt)
    if x in {SQLITE_DONE, SQLITE_ROW}:
      res = finalize(stmt) == SQLITE_OK
    else:
      discard finalize(stmt)
      res = false
  if not res:
    dbError(db)

proc getColumns*(db:PSqlite3, query:string, args:seq[string], timeout:int):Future[seq[string]] {.async.} =
  assert(not db.isNil, "Database not connected.")
  var dbRows: DbRows
  return db.getColumns(dbRows, query, args)

proc prepare*(db:PSqlite3, query:string, timeout:int):Future[PStmt] {.async.} =
  if prepare_v2(db, query, query.len.cint, result, nil) != SQLITE_OK:
    discard finalize(result)
    dbError(db)

proc preparedQuery*(db:PSqlite3, args:seq[string] = @[], sqliteStmt:PStmt):Future[(seq[Row], DbRows)] {.async.} =
  # bind params
  for i, row in args:
    sqliteStmt.bindParam(i+1, row)
  # run query
  assert(not db.isNil, "Database not connected.")
  var dbRows: DbRows
  var rows = newSeq[seq[string]]()
  for row in db.instantRows(dbRows, sqliteStmt):
    await sleepAsync(0)
    var columns = newSeq[string](row.len)
    for i in 0..row.len()-1:
      columns[i] = row[i]
    rows.add(columns)
  return (rows, dbRows)

proc preparedExec*(db:PSqlite3, args:seq[string] = @[], sqliteStmt:PStmt) {.async.} =
  # bind params
  for i, row in args:
    sqliteStmt.bindParam(i+1, row)
  # run query
  await sleepAsync(0)
  let x = step(sqliteStmt)
  var res:bool
  if x in {SQLITE_DONE, SQLITE_ROW}:
    res = true
  else:
    res = false
  discard finalize(sqliteStmt)
  if not res:
    dbError(db)
