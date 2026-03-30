import std/asyncdispatch
import std/times
import std/strutils
import std/strformat
import std/json
import ../../error
import ../../models/database_types
import ../../models/mysql/mysql_types
import ../../prepared_param
import ./mysql_rdb
import ./mysql_lib


proc rawExec(conn:PMySQL, query: string, args: seq[string]) =
  assert conn.ping == 0

  var stmt = mysql_rdb.stmt_init(conn)
  if stmt.isNil:
    mysql_rdb.close(conn)
    dbError("mysql_stmt_init() failed")

  var q = dbFormat(query, args)
  if realQuery(conn, q.cstring, q.len) != 0'i32: dbError(conn)


proc rawExec(conn:PMySQL, query: string, args: MysqlParams) =
  assert conn.ping == 0

  var stmt = mysql_rdb.stmt_init(conn)
  if stmt.isNil:
    mysql_rdb.close(conn)
    dbError("mysql_stmt_init() failed")

  var q = dbFormat(conn, query, args)
  if realQuery(conn, q.cstring, q.len) != 0'i32: dbError(conn)


proc prepareStmt*(conn: PMySQL, sql: string, timeout: int): Future[PSTMT] {.async.} =
  assert(not conn.isNil, "Database not connected.")
  await sleepAsync(0)
  result = mysql_rdb.stmt_init(conn)
  if result.isNil:
    dbError(conn)
  if mysql_rdb.stmt_prepare(result, sql.cstring, sql.len) != 0:
    let errmsg = $mysql_rdb.stmt_error(result)
    discard mysql_rdb.stmt_close(result)
    raise newException(DbError, errmsg)


proc bindStmtParams(stmt: PSTMT, args: seq[PreparedParam]) =
  if mysql_rdb.stmt_param_count(stmt) != args.len:
    raise newException(DbError, "Prepared statement parameter count mismatch.")

  if args.len == 0:
    return

  var binds = newSeq[BIND](args.len)
  var values = newSeq[string](args.len)
  var lengths = newSeq[culong](args.len)
  var nullFlags = newSeq[my_bool](args.len)
  var errorFlags = newSeq[my_bool](args.len)

  for i, arg in args:
    if arg.isNull:
      nullFlags[i] = true
      binds[i].buffer_type = TYPE_NULL
      binds[i].is_null = addr nullFlags[i]
      binds[i].error = addr errorFlags[i]
      continue

    values[i] = arg.value
    lengths[i] = values[i].len.culong
    binds[i].buffer_type = TYPE_STRING
    if values[i].len > 0:
      binds[i].buffer = cast[pointer](values[i].cstring)
    else:
      binds[i].buffer = nil
    binds[i].buffer_length = values[i].len.culong
    binds[i].length = addr lengths[i]
    binds[i].is_null = addr nullFlags[i]
    binds[i].error = addr errorFlags[i]

  if mysql_rdb.stmt_bind_param(stmt, binds[0].addr):
    raise newException(DbError, $mysql_rdb.stmt_error(stmt))


proc bindStmtResults(
    stmt: PSTMT,
    metadata: PRES,
    resultBinds: MysqlResultBindCache
) =
  let cols = int(mysql_rdb.num_fields(metadata))
  if resultBinds.binds.len != cols:
    resultBinds.binds = newSeq[BIND](cols)
    resultBinds.buffers = newSeq[string](cols)
    resultBinds.lengths = newSeq[culong](cols)
    resultBinds.nullFlags = newSeq[my_bool](cols)
    resultBinds.errorFlags = newSeq[my_bool](cols)
    for i in 0 ..< cols:
      let field = mysql_rdb.fetch_field_direct(metadata, cast[mysql_rdb.cuint](i))
      var bufferLen = int(field.len)
      if bufferLen < 4096:
        bufferLen = 4096
      resultBinds.buffers[i] = newString(bufferLen)
  else:
    for i in 0 ..< cols:
      resultBinds.lengths[i] = 0
      resultBinds.nullFlags[i] = false
      resultBinds.errorFlags[i] = false

  for i in 0 ..< cols:
    resultBinds.binds[i].buffer_type = TYPE_STRING
    resultBinds.binds[i].buffer = if resultBinds.buffers[i].len > 0: cast[pointer](resultBinds.buffers[i].cstring) else: nil
    resultBinds.binds[i].buffer_length = resultBinds.buffers[i].len.culong
    resultBinds.binds[i].length = addr resultBinds.lengths[i]
    resultBinds.binds[i].is_null = addr resultBinds.nullFlags[i]
    resultBinds.binds[i].error = addr resultBinds.errorFlags[i]

  if cols > 0 and mysql_rdb.stmt_bind_result(stmt, resultBinds.binds[0].addr):
    raise newException(DbError, $mysql_rdb.stmt_error(stmt))


proc refetchTruncatedColumns(
    stmt: PSTMT,
    resultBinds: MysqlResultBindCache
) =
  for i in 0 ..< resultBinds.binds.len:
    if not resultBinds.errorFlags[i]:
      continue
    let needed = max(int(resultBinds.lengths[i]), resultBinds.buffers[i].len)
    if needed <= 0:
      continue
    resultBinds.buffers[i] = newString(needed)
    resultBinds.binds[i].buffer = cast[pointer](resultBinds.buffers[i].cstring)
    resultBinds.binds[i].buffer_length = needed.culong
    if mysql_rdb.stmt_fetch_column(stmt, resultBinds.binds[i].addr, cast[mysql_rdb.cuint](i), 0) != 0:
      raise newException(DbError, $mysql_rdb.stmt_error(stmt))


proc execPreparedStmt*(conn: PMySQL, stmt: PSTMT, args: seq[PreparedParam], timeout: int) {.async.} =
  assert(not conn.isNil, "Database not connected.")
  await sleepAsync(0)
  if mysql_rdb.stmt_reset(stmt):
    raise newException(DbError, $mysql_rdb.stmt_error(stmt))
  if mysql_rdb.stmt_free_result(stmt):
    raise newException(DbError, $mysql_rdb.stmt_error(stmt))
  bindStmtParams(stmt, args)
  if mysql_rdb.stmt_execute(stmt) != 0:
    raise newException(DbError, $mysql_rdb.stmt_error(stmt))
  if mysql_rdb.stmt_free_result(stmt):
    raise newException(DbError, $mysql_rdb.stmt_error(stmt))


proc queryPreparedStmt*(
    conn: PMySQL,
    stmt: PSTMT,
    args: seq[PreparedParam],
    timeout: int,
    resultBinds: MysqlResultBindCache
): Future[(seq[database_types.Row], DbRows)] {.async.} =
  assert(not conn.isNil, "Database not connected.")
  await sleepAsync(0)
  if mysql_rdb.stmt_reset(stmt):
    raise newException(DbError, $mysql_rdb.stmt_error(stmt))
  if mysql_rdb.stmt_free_result(stmt):
    raise newException(DbError, $mysql_rdb.stmt_error(stmt))
  bindStmtParams(stmt, args)
  if mysql_rdb.stmt_execute(stmt) != 0:
    raise newException(DbError, $mysql_rdb.stmt_error(stmt))

  var dbRows: DbRows
  var rows = newSeq[seq[string]]()
  let metadata = mysql_rdb.stmt_result_metadata(stmt)
  if metadata.isNil:
    if mysql_rdb.stmt_free_result(stmt):
      raise newException(DbError, $mysql_rdb.stmt_error(stmt))
    return (rows, dbRows)

  defer:
    mysql_rdb.free_result(metadata)
    if mysql_rdb.stmt_free_result(stmt):
      raise newException(DbError, $mysql_rdb.stmt_error(stmt))

  if mysql_rdb.stmt_store_result(stmt) != 0:
    raise newException(DbError, $mysql_rdb.stmt_error(stmt))

  let cols = int(mysql_rdb.num_fields(metadata))
  var baseColumns: DbColumns
  setColumnInfo(baseColumns, metadata, cols)
  bindStmtResults(stmt, metadata, resultBinds)

  while true:
    let fetchRes = mysql_rdb.stmt_fetch(stmt)
    if fetchRes == 100:
      break
    if fetchRes notin {0, 101}:
      raise newException(DbError, $mysql_rdb.stmt_error(stmt))
    if fetchRes == 101:
      refetchTruncatedColumns(stmt, resultBinds)

    var rowColumns = baseColumns
    var row = newSeq[string](cols)
    for i in 0 ..< cols:
      if resultBinds.nullFlags[i]:
        rowColumns[i].typ.kind = dbNull
        row[i] = ""
      else:
        let length = min(int(resultBinds.lengths[i]), resultBinds.buffers[i].len)
        if length <= 0:
          row[i] = ""
        else:
          row[i] = resultBinds.buffers[i][0 ..< length]
    rows.add(row)
    dbRows.add(rowColumns)

  return (rows, dbRows)


proc closePreparedStmt*(stmt: PSTMT) =
  if stmt.isNil:
    return
  discard mysql_rdb.stmt_close(stmt)


proc query*(db:PMySQL, query: string, args: seq[string], timeout:int):Future[(seq[database_types.Row], DbRows)] {.async.} =
  assert db.ping == 0
  var dbRows: DbRows
  var rows = newSeq[seq[string]]()
  var lines = 0

  rawExec(db, query, args)

  var sqlres = mysql_rdb.useResult(db)
  let calledAt = getTime().toUnix()
  var dbColumns: DbColumns
  let cols = int(mysql_rdb.numFields(sqlres))

  while true:
    if getTime().toUnix() >= calledAt + timeout:
      return
    await sleepAsync(0)
    var row: mysql_rdb.Row
    var baseRow = newSeq[string](cols)
    setColumnInfo(dbColumns, sqlres, cols)
    row = mysql_rdb.fetchRow(sqlres)
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


proc query*(db:PMySQL, query: string, args: JsonNode, timeout:int):Future[(seq[database_types.Row], DbRows)] {.async.} =
  var strArgs = newSeq[string](args.len)
  var i = 0
  for arg in args.items:
    defer: i.inc()
    case arg["value"].kind
    of JBool:
      strArgs[i] = if arg["value"].getBool: "1" else: "0"
    of JInt:
      strArgs[i] = $arg["value"].getInt
    of JFloat:
      strArgs[i] = $arg["value"].getFloat
    of JArray, JObject:
      strArgs[i] = arg["value"].pretty()
    of JNull:
      strArgs[i] = "null"
    else: # JString
      strArgs[i] = arg["value"].getStr()

  return query(db, query, strArgs, timeout).await


proc queryPlain*(db:PMySQL, query: string, args: seq[string], timeout:int):Future[seq[database_types.Row]] {.async.} =
  assert db.ping == 0
  rawExec(db, query, args)
  var rows = newSeq[seq[string]]()
  var sqlres = mysql_rdb.useResult(db)
  let calledAt = getTime().toUnix()
  let cols = int(mysql_rdb.numFields(sqlres))
  while true:
    if getTime().toUnix() >= calledAt + timeout:
      return
    await sleepAsync(0)
    var row: mysql_rdb.Row
    var baseRow = newSeq[string](cols)
    row = mysql_rdb.fetchRow(sqlres)
    if row == nil: break
    for i in 0..<cols:
      baseRow[i] = $row[i]
    rows.add(baseRow)
  free_result(sqlres)
  return rows


proc queryPlain*(db:PMySQL, query: string, args: JsonNode, timeout:int):Future[seq[database_types.Row]] {.async.} =
  var strArgs = newSeq[string](args.len)
  var i = 0
  for arg in args.items:
    defer: i.inc()
    case arg.kind
    of JBool:
      strArgs[i] = if arg.getBool: "1" else: "0"
    of JInt:
      strArgs[i] = $arg.getInt
    of JFloat:
      strArgs[i] = $arg.getFloat
    of JArray, JObject:
      strArgs[i] = arg.pretty()
    of JNull:
      strArgs[i] = "null"
    else: # JString
      strArgs[i] = arg.getStr()

  return queryPlain(db, query, strArgs, timeout).await


proc exec*(db:PMySQL, query: string, args: seq[string], timeout:int) {.async.} =
  var q = dbFormat(query, args)
  await sleepAsync(0)
  if realQuery(db, q.cstring, q.len) != 0'i32: dbError(db)


proc exec*(db:PMySQL, query: string, args: JsonNode, timeout:int) {.async.} =
  var strArgs = newSeq[string](args.len)
  var i = 0
  for arg in args.items:
    defer: i.inc()
    case arg.kind
    of JBool:
      strArgs[i] = if arg.getBool: "1" else: "0"
    of JInt:
      strArgs[i] = $arg.getInt
    of JFloat:
      strArgs[i] = $arg.getFloat
    of JArray, JObject:
      strArgs[i] = arg.pretty()
    of JNull:
      strArgs[i] = "null"
    else: # JString
      strArgs[i] = arg.getStr()

  exec(db, query, strArgs, timeout).await


proc exec*(db:PMySQL, query: string, args: JsonNode, columns:seq[seq[string]], timeout:int) {.async.} =
  ## args is JArray `[{"key":"id", "value": 1}, {"key": "name" "value": "alice"}]`
  assert db.ping == 0

  let params = MysqlParams.fromObj(args, columns)
  rawExec(db, query, params)


proc execGetValue*(db:PMySQL, query: string, args: JsonNode, columns:seq[seq[string]], timeout:int):Future[(seq[database_types.Row], DbRows)] {.async.} =
  assert db.ping == 0
  var dbRows: DbRows
  var rows = newSeq[seq[string]]()
  var lines = 0

  let params = MysqlParams.fromObj(args, columns)
  rawExec(db, query, params)

  var sqlres = mysql_rdb.useResult(db)
  let calledAt = getTime().toUnix()
  var dbColumns: DbColumns
  let cols = int(mysql_rdb.numFields(sqlres))

  while true:
    if getTime().toUnix() >= calledAt + timeout:
      return
    await sleepAsync(0)
    var row: mysql_rdb.Row
    var baseRow = newSeq[string](cols)
    setColumnInfo(dbColumns, sqlres, cols)
    row = mysql_rdb.fetchRow(sqlres)
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


proc rawQuery*(db:PMySQL, query: string, args: JsonNode, timeout:int):Future[(seq[database_types.Row], DbRows)] {.async.} =
  var strArgs = newSeq[string](args.len)
  var i = 0
  for arg in args.items:
    defer: i.inc()
    case arg.kind
    of JBool:
      strArgs[i] = if arg.getBool: "1" else: "0"
    of JInt:
      strArgs[i] = $arg.getInt
    of JFloat:
      strArgs[i] = $arg.getFloat
    of JArray, JObject:
      strArgs[i] = arg.pretty()
    of JNull:
      strArgs[i] = "null"
    else: # JString
      strArgs[i] = arg.getStr()

  return query(db, query, strArgs, timeout).await


proc getColumns*(db:PMySQL, query: string, args: seq[string], timeout:int):Future[seq[string]] {.async.} =
  assert db.ping == 0
  var columns:seq[string]
  
  rawExec(db, query, args)
  var sqlres = mysql_rdb.useResult(db)
  let calledAt = getTime().toUnix()
  var dbColumns: DbColumns
  let cols = int(mysql_rdb.numFields(sqlres))
  while true:
    if getTime().toUnix() >= calledAt + timeout:
      return
    await sleepAsync(0)
    var row: mysql_rdb.Row
    setColumnInfo(dbColumns, sqlres, cols)
    for column in dbColumns:
      columns.add(column.name)
    row = mysql_rdb.fetchRow(sqlres)
    break
  free_result(sqlres)
  return columns


proc getColumnTypes*(db:PMySQL, database, table:string, timeout:int):Future[seq[database_types.Row]] {.async.} =
  assert db.ping == 0

  let sql = &"SELECT `COLUMN_NAME`, `DATA_TYPE`  FROM `INFORMATION_SCHEMA`.`COLUMNS` WHERE TABLE_SCHEMA = '{database}' AND TABLE_NAME = '{table}'" 
  return queryPlain(db, sql, @[], timeout).await
