## https://www.postgresql.jp/document/12/html/libpq-async.html

import std/asyncdispatch
import std/json
import std/monotimes
import std/strutils
import std/times
import ../../error
import ../../models/database_types
import ../../prepared_param
import ./postgres_rdb
import ./postgres_lib


type
  PgWaitState = object
    cancelled: bool

proc cancelQuery(db: PPGconn) {.raises: [DbError].} =
  let cancel = pqGetCancel(db)
  if cancel == nil:
    raise newException(DbError, "PQgetCancel failed")
  defer:
    pqFreeCancel(cancel)
  var errBuf = newStringOfCap(ERROR_MSG_LENGTH)
  errBuf.setLen(ERROR_MSG_LENGTH)
  if pqCancel(cancel, errBuf.cstring, int32(errBuf.len)) == 0:
    raise newException(DbError, "PQcancel failed: " & $errBuf.cstring)

proc ensurePgSocketRegistered(db: PPGconn): AsyncFD =
  let sock = pqsocket(db)
  if sock < 0:
    dbError(db)
  result = AsyncFD(cint(sock))
  let disp = getGlobalDispatcher()
  if not disp.contains(result):
    register(result)

proc waitPgIo(db: PPGconn, timeoutMs: int; forRead: bool): Future[bool] {.async.} =
  if timeoutMs <= 0:
    return false
  let fd = ensurePgSocketRegistered(db)
  var state = PgWaitState(cancelled: false)
  var ioFut = newFuture[void]("waitPgIo")
  if forRead:
    proc readCb(f: AsyncFD): bool =
      if state.cancelled:
        return true
      if not ioFut.finished:
        ioFut.complete()
      return true
    addRead(fd, readCb)
  else:
    proc writeCb(f: AsyncFD): bool =
      if state.cancelled:
        return true
      if not ioFut.finished:
        ioFut.complete()
      return true
    addWrite(fd, writeCb)
  let ok = await withTimeout(ioFut, timeoutMs)
  if not ok:
    state.cancelled = true
    unregister(fd)
  return ok

proc makePgDeadline(timeout: int): MonoTime =
  let sec = if timeout > 0: timeout else: 0
  getMonoTime() + initDuration(seconds = sec)

proc pgRemainingMs(deadline: MonoTime): int =
  let left = (deadline - getMonoTime()).inMilliseconds
  if left <= 0:
    return 0
  if left > int64(high(int)):
    return high(int)
  result = int(left)
  if result < 1:
    result = 1

proc pgSendQueryParams(db: PPGconn, query: string, pgParams: PGParams) {.raises: [DbError].} =
  let status =
    if pgParams.nParams > 0:
      pqsendQueryParams(db, query.cstring, pgParams.nParams, nil, pgParams.values, pgParams.lengths[0].unsafeAddr, pgParams.formats[0].unsafeAddr, 0)
    else:
      pqsendQueryParams(db, query.cstring, pgParams.nParams, nil, nil, nil, nil, 0)
  if status != 1:
    dbError(db)

proc pgFlushOutgoing(db: PPGconn, deadline: MonoTime): Future[void] {.async.} =
  while true:
    let flushRes = pqflush(db)
    if flushRes == 0:
      return
    if flushRes < 0:
      dbError(db)
    let ms = pgRemainingMs(deadline)
    if ms <= 0:
      cancelQuery(db)
      raise newException(DbError, "PostgreSQL query timeout")
    if not await waitPgIo(db, ms, false):
      cancelQuery(db)
      raise newException(DbError, "PostgreSQL query timeout")

proc pgAwaitReadyForGetResult(db: PPGconn, deadline: MonoTime): Future[void] {.async.} =
  while true:
    if pqconsumeInput(db) != 1:
      dbError(db)
    if pqisBusy(db) != 1:
      return
    let ms = pgRemainingMs(deadline)
    if ms <= 0:
      cancelQuery(db)
      raise newException(DbError, "PostgreSQL query timeout")
    if not await waitPgIo(db, ms, true):
      cancelQuery(db)
      raise newException(DbError, "PostgreSQL query timeout")

proc pgNextResult(db: PPGconn, deadline: MonoTime): Future[PPGresult] {.async.} =
  await pgAwaitReadyForGetResult(db, deadline)
  result = pqgetResult(db)

proc pgEnsureIdle(db: PPGconn, deadline: MonoTime): Future[void] {.async.} =
  while true:
    await pgAwaitReadyForGetResult(db, deadline)
    let r = pqgetResult(db)
    if r == nil:
      db.checkError()
      return
    pqclear(r)


proc query*(db: PPGconn, query: string, args: JsonNode, timeout: int): Future[(seq[Row], DbRows)] {.async.} =
  assert db.status == CONNECTION_OK
  let pgParams = PGParams.fromObjArray(args)
  defer:
    if pgParams.nParams > 0: pgParams.values.deallocCStringArray()
  pgSendQueryParams(db, query, pgParams)
  var dbRows: DbRows
  var rows = newSeq[Row]()
  let deadline = makePgDeadline(timeout)
  await pgFlushOutgoing(db, deadline)
  while true:
    let pqresult = await pgNextResult(db, deadline)
    if pqresult == nil:
      db.checkError()
      break

    let cols = pqnfields(pqresult)
    var row = newRow(cols)
    let base = buildBaseDbColumns(pqresult, cols)
    for i in 0'i32 .. pqNtuples(pqresult) - 1:
      setRow(pqresult, row, i, cols)
      appendDbRowWithBaseColumns(pqresult, dbRows, i, cols, base)
      rows.add(row)
    pqclear(pqresult)

  return (rows, dbRows)


proc exec*(db: PPGconn, query: string, args: JsonNode, columns: seq[Row], timeout: int) {.async.} =
  assert db.status == CONNECTION_OK
  let pgParams = PGParams.fromObjArray(args, columns)
  defer:
    if pgParams.nParams > 0: pgParams.values.deallocCStringArray()
  pgSendQueryParams(db, query, pgParams)
  let deadline = makePgDeadline(timeout)
  await pgFlushOutgoing(db, deadline)
  while true:
    let pqresult = await pgNextResult(db, deadline)
    if pqresult == nil:
      db.checkError()
      break
    pqclear(pqresult)


proc execGetValue*(db: PPGconn, query: string, args: JsonNode, columns: seq[Row], timeout: int): Future[(seq[Row], DbRows)] {.async.} =
  assert db.status == CONNECTION_OK
  let pgParams = PGParams.fromObjArray(args, columns)
  defer:
    if pgParams.nParams > 0: pgParams.values.deallocCStringArray()
  pgSendQueryParams(db, query, pgParams)
  var dbRows: DbRows
  var rows = newSeq[Row]()
  let deadline = makePgDeadline(timeout)
  await pgFlushOutgoing(db, deadline)
  while true:
    let pqresult = await pgNextResult(db, deadline)
    if pqresult == nil:
      db.checkError()
      break

    let cols = pqnfields(pqresult)
    var row = newRow(cols)
    let base = buildBaseDbColumns(pqresult, cols)
    for i in 0'i32 .. pqNtuples(pqresult) - 1:
      setRow(pqresult, row, i, cols)
      appendDbRowWithBaseColumns(pqresult, dbRows, i, cols, base)
      rows.add(row)
    pqclear(pqresult)

  return (rows, dbRows)


proc rawQuery*(db: PPGconn, query: string, args: JsonNode, timeout: int): Future[(seq[Row], DbRows)] {.async.} =
  assert db.status == CONNECTION_OK
  let pgParams = PGParams.fromArray(args)
  defer:
    if pgParams.nParams > 0: pgParams.values.deallocCStringArray()
  pgSendQueryParams(db, query, pgParams)
  var dbRows: DbRows
  var rows = newSeq[Row]()
  let deadline = makePgDeadline(timeout)
  await pgFlushOutgoing(db, deadline)
  while true:
    let pqresult = await pgNextResult(db, deadline)
    if pqresult == nil:
      db.checkError()
      break

    let cols = pqnfields(pqresult)
    var row = newRow(cols)
    let base = buildBaseDbColumns(pqresult, cols)
    for i in 0'i32 .. pqNtuples(pqresult) - 1:
      setRow(pqresult, row, i, cols)
      appendDbRowWithBaseColumns(pqresult, dbRows, i, cols, base)
      rows.add(row)
    pqclear(pqresult)

  return (rows, dbRows)


proc rawExec*(db: PPGconn, query: string, args: JsonNode, timeout: int) {.async.} =
  assert db.status == CONNECTION_OK
  let pgParams = PGParams.fromArray(args)
  defer:
    if pgParams.nParams > 0: pgParams.values.deallocCStringArray()
  pgSendQueryParams(db, query, pgParams)
  let deadline = makePgDeadline(timeout)
  await pgFlushOutgoing(db, deadline)
  while true:
    let pqresult = await pgNextResult(db, deadline)
    if pqresult == nil:
      db.checkError()
      break
    pqclear(pqresult)


# ==================================================
# Old functions
# ==================================================

proc query*(db: PPGconn, query: string, args: seq[string], timeout: int): Future[(seq[Row], DbRows)] {.async.} =
  assert db.status == CONNECTION_OK
  let status = pqsendQuery(db, dbFormat(query, args).cstring)
  if status != 1: dbError(db)
  var dbRows: DbRows
  var rows = newSeq[Row]()
  let deadline = makePgDeadline(timeout)
  await pgFlushOutgoing(db, deadline)
  while true:
    let pqresult = await pgNextResult(db, deadline)
    if pqresult == nil:
      db.checkError()
      break

    let cols = pqnfields(pqresult)
    var row = newRow(cols)
    let base = buildBaseDbColumns(pqresult, cols)
    for i in 0'i32 .. pqNtuples(pqresult) - 1:
      setRow(pqresult, row, i, cols)
      appendDbRowWithBaseColumns(pqresult, dbRows, i, cols, base)
      rows.add(row)
    pqclear(pqresult)

  return (rows, dbRows)

proc queryPlain*(db: PPGconn, query: string, args: seq[string], timeout: int): Future[seq[Row]] {.async.} =
  assert db.status == CONNECTION_OK
  let status = pqsendQuery(db, dbFormat(query, args).cstring)
  if status != 1: dbError(db)
  var rows = newSeq[Row]()
  let deadline = makePgDeadline(timeout)
  await pgFlushOutgoing(db, deadline)
  while true:
    let pqresult = await pgNextResult(db, deadline)
    if pqresult == nil:
      db.checkError()
      break

    var cols = pqnfields(pqresult)
    var row = newRow(cols)
    for i in 0'i32 .. pqNtuples(pqresult) - 1:
      setRow(pqresult, row, i, cols)
      rows.add(row)
    pqclear(pqresult)

  return rows


proc exec*(db: PPGconn, query: string, args: seq[string], timeout: int) {.async.} =
  assert db.status == CONNECTION_OK
  let success = pqsendQuery(db, dbFormat(query, args).cstring)
  if success != 1: dbError(db)
  let deadline = makePgDeadline(timeout)
  await pgFlushOutgoing(db, deadline)
  while true:
    let pqresult = await pgNextResult(db, deadline)
    if pqresult == nil:
      db.checkError()
      break
    pqclear(pqresult)


proc getColumns*(db: PPGconn, query: string, args: seq[string], timeout: int): Future[seq[string]] {.async.} =
  assert db.status == CONNECTION_OK
  let status = pqsendQuery(db, dbFormat(query, args).cstring)
  if status != 1: dbError(db)
  var dbRows: DbRows
  let deadline = makePgDeadline(timeout)
  await pgFlushOutgoing(db, deadline)
  while true:
    let pqresult = await pgNextResult(db, deadline)
    if pqresult == nil:
      db.checkError()
      break

    let cols = pqnfields(pqresult)
    let base = buildBaseDbColumns(pqresult, cols)
    appendDbRowWithBaseColumns(pqresult, dbRows, 0, cols, base)
    pqclear(pqresult)

  for column in dbRows[0]:
    result.add(column.name)


proc prepare*(db: PPGconn, query: string, timeout: int, stmtName: string, nArgs: int): Future[void] {.async.} =
  assert db.status == CONNECTION_OK
  let success = pqsendPrepare(db, stmtName, questionToDaller(query).cstring, int32(nArgs), nil)
  if success != 1: dbError(db)
  let deadline = makePgDeadline(timeout)
  await pgFlushOutgoing(db, deadline)
  while true:
    let pqresult = await pgNextResult(db, deadline)
    if pqresult == nil:
      db.checkError()
      break
    pqclear(pqresult)


proc deallocate*(db: PPGconn, stmtName: string, timeout: int): Future[void] {.async.} =
  assert db.status == CONNECTION_OK
  if stmtName.len == 0:
    return
  let success = pqsendQuery(db, ("DEALLOCATE " & stmtName).cstring)
  if success != 1:
    dbError(db)
  let deadline = makePgDeadline(timeout)
  await pgFlushOutgoing(db, deadline)
  while true:
    let pqresult = await pgNextResult(db, deadline)
    if pqresult == nil:
      db.checkError()
      break
    pqclear(pqresult)

proc allocPreparedCStringArray(args: seq[PreparedParam]): cstringArray =
  result = cast[cstringArray](alloc0((args.len + 1) * sizeof(cstring)))
  for i, arg in args:
    if arg.isNull:
      continue
    let cstrLen = arg.value.len + 1
    let cstr = cast[cstring](alloc0(cstrLen))
    copyMem(cstr, arg.value.cstring, arg.value.len)
    result[i] = cstr


proc freePreparedCStringArray(values: cstringArray, n: int) =
  if values.isNil:
    return
  for i in 0 ..< n:
    if values[i] != nil:
      dealloc(values[i])
  dealloc(values)


proc preparedQuery*(db: PPGconn, args: seq[PreparedParam], nArgs: int, timeout: int, stmtName: string): Future[(seq[Row], DbRows)] {.async.} =
  assert db.status == CONNECTION_OK
  let deadline = makePgDeadline(timeout)
  await pgEnsureIdle(db, deadline)
  let values = allocPreparedCStringArray(args)
  defer:
    freePreparedCStringArray(values, args.len)
  let status = pqsendQueryPrepared(db, stmtName, int32(nArgs), values, nil, nil, 0)
  if status != 1: dbError(db)
  var dbRows: DbRows
  var rows = newSeq[Row]()
  await pgFlushOutgoing(db, deadline)
  while true:
    let pqresult = await pgNextResult(db, deadline)
    if pqresult == nil:
      db.checkError()
      break

    let cols = pqnfields(pqresult)
    var row = newRow(cols)
    let base = buildBaseDbColumns(pqresult, cols)
    for i in 0'i32 .. pqNtuples(pqresult) - 1:
      setRow(pqresult, row, i, cols)
      appendDbRowWithBaseColumns(pqresult, dbRows, i, cols, base)
      rows.add(row)
    pqclear(pqresult)

  return (rows, dbRows)

proc preparedExec*(db: PPGconn, args: seq[PreparedParam], nArgs: int, timeout: int, stmtName: string) {.async.} =
  assert db.status == CONNECTION_OK
  let deadline = makePgDeadline(timeout)
  await pgEnsureIdle(db, deadline)
  let values = allocPreparedCStringArray(args)
  defer:
    freePreparedCStringArray(values, args.len)
  let status = pqsendQueryPrepared(db, stmtName, int32(nArgs), values, nil, nil, 0)
  if status != 1: dbError(db)
  await pgFlushOutgoing(db, deadline)
  while true:
    let pqresult = await pgNextResult(db, deadline)
    if pqresult == nil:
      db.checkError()
      break
    pqclear(pqresult)
