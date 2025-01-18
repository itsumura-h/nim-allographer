import std/asyncdispatch
import std/strutils
import std/json
import ../../models/database_types
import ./sqlite_rdb
import ./sqlite_lib


proc query*(db:PSqlite3, query:string, args:seq[string], timeout:int):Future[(seq[Row], DbRows)] {.async.} =
  assert(not db.isNil, "Database not connected.")
  sleepAsync(0).await
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
  sleepAsync(0).await
  var rows = newSeq[seq[string]]()
  for row in db.instantRowsPlain(query, args):
    var columns = newSeq[string](row.len)
    for i in 0..row.len()-1:
      columns[i] = row[i]
    rows.add(columns)
  return rows


proc getColumnTypes*(db:PSqlite3, query: string):Future[seq[(string, string)]] {.async.} =
  sleepAsync(0).await
  var dbRows: DbRows
  var columns = newSeq[(string, string)]()
  for row in db.instantRows(dbRows, query, newSeq[string]()):
    columns.add((row[1], row[2]))
  return columns


proc exec*(db:PSqlite3, query: string, args: JsonNode, columns:seq[(string, string)], timeout:int) {.async.} =
  ## args is `JArray`
  assert(not db.isNil, "Database not connected.")
  sleepAsync(0).await
  # var q = dbFormat(query, strArges)
  var stmt: PStmt
  var res:bool
  if prepare_v2(db, query.cstring, query.len.cint, stmt, nil) == SQLITE_OK:
    var argCount = 1
    for arg in args.items:
      defer: argCount.inc()
      case arg["value"].kind
      of JBool:
        let value = arg["value"].getBool
        let insertVal = if value:1 else: 0
        discard bind_int64(stmt, argCount.int32, insertVal)
      of JInt:
        let value = arg["value"].getInt
        discard bind_int64(stmt, argCount.int32, value)
      of JFloat:
        let value = arg["value"].getFloat
        discard bind_double(stmt, argCount.int32, value.float64)
      of JNull:
        discard bind_null(stmt, argCount.int32)
      of JObject, JArray:
        let value = arg["value"].pretty
        discard bind_text(stmt, argCount.int32, value.cstring, value.len.int32, SQLITE_TRANSIENT)
      of JString:
        for column in columns:
          let columnName = column[0]
          let columnTyp = column[1]
          if columnName == arg["key"].getStr:
            defer: break
            if columnTyp == "BLOB":
              let value = arg["value"].getStr
              var blobVal:seq[byte]
              for c in value:
                blobVal.add(c.byte)
              discard bind_blob(stmt, argCount.int32, blobVal[0].unsafeAddr, blobVal.len.int32, SQLITE_TRANSIENT)
            else:
              let value = arg["value"].getStr
              discard bind_text(stmt, argCount.int32, value.cstring, value.len.int32, SQLITE_TRANSIENT)

    let x = step(stmt)
    if x in {SQLITE_DONE, SQLITE_ROW}:
      res = finalize(stmt) == SQLITE_OK
    else:
      discard finalize(stmt)
      res = false
  if not res:
    dbError(db)


proc exec*(db:PSqlite3, query: string, args: JsonNode, timeout:int) {.async.} =
  ## used for rdb.raw().exec()
  ## args are `JArray`
  assert(not db.isNil, "Database not connected.")
  sleepAsync(0).await
  var stmt: PStmt
  var res:bool
  if prepare_v2(db, query.cstring, query.len.cint, stmt, nil) == SQLITE_OK:
    var argCount = 1
    for arg in args.items:
      defer: argCount.inc()
      case arg.kind
      of JBool:
        let value = arg.getBool
        let insertVal = if value:1 else: 0
        discard bind_int64(stmt, argCount.int32, insertVal)
      of JInt:
        let value = arg.getInt
        discard bind_int64(stmt, argCount.int32, value)
      of JFloat:
        let value = arg.getFloat
        discard bind_double(stmt, argCount.int32, value.float64)
      of JNull:
        discard bind_null(stmt, argCount.int32)
      of JObject, JArray:
        let value = arg.pretty
        discard bind_text(stmt, argCount.int32, value.cstring, value.len.int32, SQLITE_TRANSIENT)
      of JString:
        let value = arg.getStr
        discard bind_text(stmt, argCount.int32, value.cstring, value.len.int32, SQLITE_TRANSIENT)

    let x = step(stmt)
    if x in {SQLITE_DONE, SQLITE_ROW}:
      res = finalize(stmt) == SQLITE_OK
    else:
      discard finalize(stmt)
      res = false
  if not res:
    dbError(db)


proc exec*(db:PSqlite3, query: string, args: seq[string], timeout:int) {.async.} =
  ## Not used anymore
  assert(not db.isNil, "Database not connected.")
  sleepAsync(0).await
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
  sleepAsync(0).await
  var dbRows: DbRows
  return db.getColumns(dbRows, query, args)


proc prepare*(db:PSqlite3, query:string, timeout:int):Future[PStmt] {.async.} =
  sleepAsync(0).await
  if prepare_v2(db, query, query.len.cint, result, nil) != SQLITE_OK:
    discard finalize(result)
    dbError(db)


proc preparedQuery*(db:PSqlite3, args:seq[string] = @[], sqliteStmt:PStmt):Future[(seq[Row], DbRows)] {.async.} =
  # bind params
  for i, row in args:
    sqliteStmt.bindParam(i+1, row)
  # run query
  assert(not db.isNil, "Database not connected.")
  sleepAsync(0).await
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
