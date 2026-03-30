import std/asyncdispatch
import std/monotimes
import std/times
import std/json
import ../../error
import ../../models/database_types
import ../../models/mariadb/mariadb_types
import ../../prepared_param
import ./mariadb_rdb
import ./mariadb_lib


type
  MariadbWaitState = object
    cancelled: bool

proc mariadbTimeoutError(): ref DbError =
  newException(DbError, "MariaDB query timeout")

proc makeDeadline(timeout: int): MonoTime =
  if timeout > 0:
    result = getMonoTime() + initDuration(seconds = timeout)
  else:
    result = getMonoTime()

proc remainingMs(deadline: MonoTime): int =
  let left = (deadline - getMonoTime()).inMilliseconds
  if left <= 0:
    return 0
  if left > int64(high(int)):
    return high(int)
  result = int(left)
  if result < 1:
    result = 1

proc ensureMariadbSocketRegistered(conn: PMySQL): AsyncFD =
  let sock = mariadb_rdb.get_socket(conn)
  if sock < 0:
    dbError(conn)
  result = AsyncFD(cint(sock))
  let disp = getGlobalDispatcher()
  if not disp.contains(result):
    register(result)

proc waitMariadb(conn: PMySQL, waitStatus: cint, deadline: MonoTime): Future[cint] {.async.} =
  if waitStatus == 0:
    return 0

  let totalRemaining = remainingMs(deadline)
  if totalRemaining <= 0:
    raise mariadbTimeoutError()

  var stepTimeout = totalRemaining
  if (waitStatus and MYSQL_WAIT_TIMEOUT) != 0:
    let connectorTimeout = int(mariadb_rdb.get_timeout_value_ms(conn))
    if connectorTimeout > 0 and connectorTimeout < stepTimeout:
      stepTimeout = connectorTimeout
  if stepTimeout < 1:
    stepTimeout = 1

  let shouldWaitRead = (waitStatus and (MYSQL_WAIT_READ or MYSQL_WAIT_EXCEPT)) != 0
  let shouldWaitWrite = (waitStatus and MYSQL_WAIT_WRITE) != 0

  if not shouldWaitRead and not shouldWaitWrite:
    await sleepAsync(stepTimeout)
    return cint(MYSQL_WAIT_TIMEOUT)

  let fd = ensureMariadbSocketRegistered(conn)
  var state = MariadbWaitState(cancelled: false)
  var ioReady = newFuture[void]("waitMariadb")
  var readyStatus = 0.cint

  if shouldWaitRead:
    proc readCb(f: AsyncFD): bool =
      if state.cancelled:
        return true
      readyStatus = readyStatus or cint(MYSQL_WAIT_READ)
      if (waitStatus and MYSQL_WAIT_EXCEPT) != 0:
        readyStatus = readyStatus or cint(MYSQL_WAIT_EXCEPT)
      if not ioReady.finished:
        ioReady.complete()
      return true
    addRead(fd, readCb)

  if shouldWaitWrite:
    proc writeCb(f: AsyncFD): bool =
      if state.cancelled:
        return true
      readyStatus = readyStatus or cint(MYSQL_WAIT_WRITE)
      if not ioReady.finished:
        ioReady.complete()
      return true
    addWrite(fd, writeCb)

  let ok = await withTimeout(ioReady, stepTimeout)
  if not ok:
    state.cancelled = true
    unregister(fd)
    if (waitStatus and MYSQL_WAIT_TIMEOUT) != 0:
      return cint(MYSQL_WAIT_TIMEOUT)
    raise mariadbTimeoutError()

  if readyStatus == 0:
    if (waitStatus and MYSQL_WAIT_TIMEOUT) != 0:
      return cint(MYSQL_WAIT_TIMEOUT)
    return waitStatus and cint(MYSQL_WAIT_READ or MYSQL_WAIT_WRITE or MYSQL_WAIT_EXCEPT)

  return readyStatus

proc runRealQuery(conn: PMySQL, q: string, deadline: MonoTime): Future[void] {.async.} =
  var queryStatus = 0'i32
  var waitStatus = mariadb_rdb.real_query_start(addr queryStatus, conn, q.cstring, culong(q.len))
  while waitStatus != 0:
    let ready = await waitMariadb(conn, waitStatus, deadline)
    waitStatus = mariadb_rdb.real_query_cont(addr queryStatus, conn, ready)
  if queryStatus != 0'i32:
    dbError(conn)

proc runFetchRow(conn: PMySQL, sqlres: PRES, deadline: MonoTime): Future[mariadb_rdb.Row] {.async.} =
  var row: mariadb_rdb.Row = nil
  var waitStatus = mariadb_rdb.fetch_row_start(addr row, sqlres)
  while waitStatus != 0:
    let ready = await waitMariadb(conn, waitStatus, deadline)
    waitStatus = mariadb_rdb.fetch_row_cont(addr row, sqlres, ready)
  return row

proc runFreeResult(conn: PMySQL, sqlres: PRES, deadline: MonoTime): Future[void] {.async.} =
  if sqlres.isNil:
    return
  var waitStatus = mariadb_rdb.free_result_start(sqlres)
  while waitStatus != 0:
    let ready = await waitMariadb(conn, waitStatus, deadline)
    waitStatus = mariadb_rdb.free_result_cont(sqlres, ready)

proc rawExec(conn: PMySQL, query: string, args: MariadbParams, timeout: int) {.async.} =
  let q = dbFormat(conn, query, args)
  let deadline = makeDeadline(timeout)
  await runRealQuery(conn, q, deadline)


proc runStmtPrepare(conn: PMySQL, stmt: PSTMT, sql: string, deadline: MonoTime): Future[void] {.async.} =
  var ret = 0.cint
  var waitStatus = stmt_prepare_start(addr ret, stmt, sql.cstring, culong(sql.len))
  while waitStatus != 0:
    let ready = await waitMariadb(conn, waitStatus, deadline)
    waitStatus = stmt_prepare_cont(addr ret, stmt, ready)
  if ret != 0:
    raise newException(DbError, $stmt_error(stmt))


proc runStmtReset(conn: PMySQL, stmt: PSTMT, deadline: MonoTime): Future[void] {.async.} =
  var ret = false
  var waitStatus = stmt_reset_start(addr ret, stmt)
  while waitStatus != 0:
    let ready = await waitMariadb(conn, waitStatus, deadline)
    waitStatus = stmt_reset_cont(addr ret, stmt, ready)
  if ret:
    raise newException(DbError, $stmt_error(stmt))


proc runStmtFreeResult(conn: PMySQL, stmt: PSTMT, deadline: MonoTime): Future[void] {.async.} =
  var ret = false
  var waitStatus = stmt_free_result_start(addr ret, stmt)
  while waitStatus != 0:
    let ready = await waitMariadb(conn, waitStatus, deadline)
    waitStatus = stmt_free_result_cont(addr ret, stmt, ready)
  if ret:
    raise newException(DbError, $stmt_error(stmt))


proc runStmtExecute(conn: PMySQL, stmt: PSTMT, deadline: MonoTime): Future[void] {.async.} =
  var ret = 0.cint
  var waitStatus = stmt_execute_start(addr ret, stmt)
  while waitStatus != 0:
    let ready = await waitMariadb(conn, waitStatus, deadline)
    waitStatus = stmt_execute_cont(addr ret, stmt, ready)
  if ret != 0:
    raise newException(DbError, $stmt_error(stmt))


proc runStmtStoreResult(conn: PMySQL, stmt: PSTMT, deadline: MonoTime): Future[void] {.async.} =
  var ret = 0.cint
  var waitStatus = stmt_store_result_start(addr ret, stmt)
  while waitStatus != 0:
    let ready = await waitMariadb(conn, waitStatus, deadline)
    waitStatus = stmt_store_result_cont(addr ret, stmt, ready)
  if ret != 0:
    raise newException(DbError, $stmt_error(stmt))


proc runStmtFetch(conn: PMySQL, stmt: PSTMT, deadline: MonoTime): Future[cint] {.async.} =
  var ret = 0.cint
  var waitStatus = stmt_fetch_start(addr ret, stmt)
  while waitStatus != 0:
    let ready = await waitMariadb(conn, waitStatus, deadline)
    waitStatus = stmt_fetch_cont(addr ret, stmt, ready)
  return ret


proc prepareStmt*(conn: PMySQL, sql: string, timeout: int): Future[PSTMT] {.async.} =
  assert(not conn.isNil, "Database not connected.")
  result = stmt_init(conn)
  if result.isNil:
    dbError(conn)
  let deadline = makeDeadline(timeout)
  try:
    await runStmtPrepare(conn, result, sql, deadline)
  except CatchableError:
    discard stmt_close(result)
    raise


proc bindStmtParams(stmt: PSTMT, args: seq[PreparedParam]) =
  if stmt_param_count(stmt) != args.len:
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

  if stmt_bind_param(stmt, binds[0].addr):
    raise newException(DbError, $stmt_error(stmt))


proc bindStmtResults(
    stmt: PSTMT,
    metadata: PRES,
    resultBinds: MariadbResultBindCache
) =
  let cols = int(num_fields(metadata))
  if resultBinds.binds.len != cols:
    resultBinds.binds = newSeq[BIND](cols)
    resultBinds.buffers = newSeq[string](cols)
    resultBinds.lengths = newSeq[culong](cols)
    resultBinds.nullFlags = newSeq[my_bool](cols)
    resultBinds.errorFlags = newSeq[my_bool](cols)
    for i in 0 ..< cols:
      let field = fetch_field_direct(metadata, cast[mariadb_rdb.cuint](i))
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

  if cols > 0 and stmt_bind_result(stmt, resultBinds.binds[0].addr):
    raise newException(DbError, $stmt_error(stmt))


proc refetchTruncatedColumns(
    stmt: PSTMT,
    resultBinds: MariadbResultBindCache
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
    if stmt_fetch_column(stmt, resultBinds.binds[i].addr, cast[mariadb_rdb.cuint](i), 0) != 0:
      raise newException(DbError, $stmt_error(stmt))


proc execPreparedStmt*(conn: PMySQL, stmt: PSTMT, args: seq[PreparedParam], timeout: int) {.async.} =
  assert(not conn.isNil, "Database not connected.")
  let deadline = makeDeadline(timeout)
  await runStmtReset(conn, stmt, deadline)
  await runStmtFreeResult(conn, stmt, deadline)
  bindStmtParams(stmt, args)
  await runStmtExecute(conn, stmt, deadline)
  await runStmtFreeResult(conn, stmt, deadline)


proc queryPreparedStmt*(
    conn: PMySQL,
    stmt: PSTMT,
    args: seq[PreparedParam],
    timeout: int,
    resultBinds: MariadbResultBindCache
): Future[(seq[database_types.Row], DbRows)] {.async.} =
  assert(not conn.isNil, "Database not connected.")
  let deadline = makeDeadline(timeout)
  await runStmtReset(conn, stmt, deadline)
  await runStmtFreeResult(conn, stmt, deadline)
  bindStmtParams(stmt, args)
  await runStmtExecute(conn, stmt, deadline)

  var dbRows: DbRows
  var rows = newSeq[seq[string]]()
  let metadata = stmt_result_metadata(stmt)
  if metadata.isNil:
    await runStmtFreeResult(conn, stmt, deadline)
    return (rows, dbRows)

  defer:
    free_result(metadata)
    await runStmtFreeResult(conn, stmt, deadline)

  await runStmtStoreResult(conn, stmt, deadline)

  let cols = int(num_fields(metadata))
  var baseColumns: DbColumns
  setColumnInfo(baseColumns, metadata, cols)
  bindStmtResults(stmt, metadata, resultBinds)

  while true:
    let fetchRes = await runStmtFetch(conn, stmt, deadline)
    if fetchRes == 100:
      break
    if fetchRes notin {0, 101}:
      raise newException(DbError, $stmt_error(stmt))
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


proc closePreparedStmt*(stmt: PSTMT): void =
  if stmt.isNil:
    return
  discard stmt_close(stmt)


proc jsonObjValuesToStrSeq(args: JsonNode): seq[string] =
  result = newSeq[string](args.len)
  var i = 0
  for arg in args.items:
    case arg["value"].kind
    of JBool:
      result[i] = if arg["value"].getBool: "1" else: "0"
    of JInt:
      result[i] = $arg["value"].getInt
    of JFloat:
      result[i] = $arg["value"].getFloat
    of JArray, JObject:
      result[i] = arg["value"].pretty()
    of JNull:
      result[i] = "null"
    else:
      result[i] = arg["value"].getStr()
    inc i

proc jsonFlatToStrSeq(args: JsonNode): seq[string] =
  result = newSeq[string](args.len)
  var i = 0
  for arg in args.items:
    case arg.kind
    of JBool:
      result[i] = if arg.getBool: "1" else: "0"
    of JInt:
      result[i] = $arg.getInt
    of JFloat:
      result[i] = $arg.getFloat
    of JArray, JObject:
      result[i] = arg.pretty()
    of JNull:
      result[i] = "null"
    else:
      result[i] = arg.getStr()
    inc i


proc query*(db: PMySQL, query: string, args: seq[string], timeout: int): Future[(seq[database_types.Row], DbRows)] {.async.} =
  var dbRows: DbRows
  var rows = newSeq[seq[string]]()

  let q = dbFormat(query, args)
  let deadline = makeDeadline(timeout)
  await runRealQuery(db, q, deadline)

  let sqlres = mariadb_rdb.use_result(db)
  if sqlres.isNil:
    return (rows, dbRows)

  try:
    let cols = int(mariadb_rdb.numFields(sqlres))
    var baseColumns: DbColumns
    setColumnInfo(baseColumns, sqlres, cols)
    while true:
      let row = await runFetchRow(db, sqlres, deadline)
      if row == nil:
        break

      var baseRow = newSeq[string](cols)
      var rowColumns = baseColumns
      for i in 0 ..< cols:
        if row[i].isNil:
          rowColumns[i].typ.kind = dbNull
        baseRow[i] = $row[i]
      rows.add(baseRow)
      dbRows.add(rowColumns)
  finally:
    await runFreeResult(db, sqlres, deadline)

  return (rows, dbRows)

proc query*(db: PMySQL, query: string, args: JsonNode, timeout: int): Future[(seq[database_types.Row], DbRows)] {.async.} =
  return query(db, query, jsonObjValuesToStrSeq(args), timeout).await

proc queryPlain*(db: PMySQL, query: string, args: seq[string], timeout: int): Future[seq[database_types.Row]] {.async.} =
  let q = dbFormat(query, args)
  let deadline = makeDeadline(timeout)
  await runRealQuery(db, q, deadline)

  var rows = newSeq[seq[string]]()
  let sqlres = mariadb_rdb.use_result(db)
  if sqlres.isNil:
    return rows

  try:
    let cols = int(mariadb_rdb.numFields(sqlres))
    while true:
      let row = await runFetchRow(db, sqlres, deadline)
      if row == nil:
        break

      var baseRow = newSeq[string](cols)
      for i in 0 ..< cols:
        baseRow[i] = $row[i]
      rows.add(baseRow)
  finally:
    await runFreeResult(db, sqlres, deadline)

  return rows

proc queryPlain*(db: PMySQL, query: string, args: JsonNode, timeout: int): Future[seq[database_types.Row]] {.async.} =
  return queryPlain(db, query, jsonFlatToStrSeq(args), timeout).await

proc exec*(db: PMySQL, query: string, args: seq[string], timeout: int) {.async.} =
  let q = dbFormat(query, args)
  let deadline = makeDeadline(timeout)
  await runRealQuery(db, q, deadline)

proc exec*(db: PMySQL, query: string, args: JsonNode, timeout: int) {.async.} =
  exec(db, query, jsonFlatToStrSeq(args), timeout).await

proc exec*(db: PMySQL, query: string, args: JsonNode, columns: seq[seq[string]], timeout: int) {.async.} =
  let params = MariadbParams.fromObj(args, columns)
  await rawExec(db, query, params, timeout)

proc execGetValue*(db: PMySQL, query: string, args: JsonNode, columns: seq[seq[string]], timeout: int): Future[(seq[database_types.Row], DbRows)] {.async.} =
  var dbRows: DbRows
  var rows = newSeq[seq[string]]()

  let params = MariadbParams.fromObj(args, columns)
  let deadline = makeDeadline(timeout)
  let q = dbFormat(db, query, params)
  await runRealQuery(db, q, deadline)

  let sqlres = mariadb_rdb.use_result(db)
  if sqlres.isNil:
    return (rows, dbRows)

  try:
    let cols = int(mariadb_rdb.numFields(sqlres))
    var baseColumns: DbColumns
    setColumnInfo(baseColumns, sqlres, cols)
    while true:
      let row = await runFetchRow(db, sqlres, deadline)
      if row == nil:
        break

      var baseRow = newSeq[string](cols)
      var rowColumns = baseColumns
      for i in 0 ..< cols:
        if row[i].isNil:
          rowColumns[i].typ.kind = dbNull
        baseRow[i] = $row[i]
      rows.add(baseRow)
      dbRows.add(rowColumns)
  finally:
    await runFreeResult(db, sqlres, deadline)

  return (rows, dbRows)

proc rawQuery*(db: PMySQL, query: string, args: JsonNode, timeout: int): Future[(seq[database_types.Row], DbRows)] {.async.} =
  return query(db, query, jsonFlatToStrSeq(args), timeout).await

proc getColumns*(db: PMySQL, query: string, args: seq[string], timeout: int): Future[seq[string]] {.async.} =
  var columns: seq[string]
  let q = dbFormat(query, args)
  let deadline = makeDeadline(timeout)
  await runRealQuery(db, q, deadline)

  let sqlres = mariadb_rdb.use_result(db)
  if sqlres.isNil:
    return columns

  try:
    var dbColumns: DbColumns
    let cols = int(mariadb_rdb.numFields(sqlres))
    if cols <= 0:
      return columns
    setColumnInfo(dbColumns, sqlres, cols)
    for column in dbColumns:
      columns.add(column.name)
  finally:
    await runFreeResult(db, sqlres, deadline)

  return columns

proc getColumnTypes*(db: PMySQL, database, table: string, timeout: int): Future[seq[database_types.Row]] {.async.} =
  let sql = "SELECT `COLUMN_NAME`, `DATA_TYPE` FROM `INFORMATION_SCHEMA`.`COLUMNS` WHERE TABLE_SCHEMA = ? AND TABLE_NAME = ?"
  return queryPlain(db, sql, @[database, table], timeout).await
