## https://www.postgresql.jp/document/12/html/libpq-async.html

import std/asyncdispatch
import std/json
import std/strutils
import std/times
import ../../error
import ../../models/database_types
import ./postgres_rdb
import ./postgres_lib


type
  PgWaitState = ref object
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

proc ensurePgSocketRegistered(db: PPGconn) =
  let sock = pqsocket(db)
  if sock < 0:
    dbError(db)
  let fd = AsyncFD(cint(sock))
  let disp = getGlobalDispatcher()
  if not disp.contains(fd):
    register(fd)

proc waitPgReadable(db: PPGconn, timeoutMs: int): Future[bool] {.async.} =
  if timeoutMs <= 0:
    return false
  ensurePgSocketRegistered(db)
  let sock = pqsocket(db)
  if sock < 0:
    dbError(db)
  let fd = AsyncFD(cint(sock))
  let state = PgWaitState(cancelled: false)
  var readFut = newFuture[void]("waitPgReadable")
  proc readCb(f: AsyncFD): bool =
    if state.cancelled:
      return true
    if not readFut.finished:
      readFut.complete()
    return true
  addRead(fd, readCb)
  let ok = await withTimeout(readFut, timeoutMs)
  if not ok:
    state.cancelled = true
    unregister(fd)
  return ok

proc waitPgWritable(db: PPGconn, timeoutMs: int): Future[bool] {.async.} =
  if timeoutMs <= 0:
    return false
  ensurePgSocketRegistered(db)
  let sock = pqsocket(db)
  if sock < 0:
    dbError(db)
  let fd = AsyncFD(cint(sock))
  let state = PgWaitState(cancelled: false)
  var writeFut = newFuture[void]("waitPgWritable")
  proc writeCb(f: AsyncFD): bool =
    if state.cancelled:
      return true
    if not writeFut.finished:
      writeFut.complete()
    return true
  addWrite(fd, writeCb)
  let ok = await withTimeout(writeFut, timeoutMs)
  if not ok:
    state.cancelled = true
    unregister(fd)
  return ok

proc pgRemainingMs(deadline: int64): int =
  let leftSec = deadline - getTime().toUnix()
  if leftSec <= 0:
    return 0
  result = int(leftSec * 1000)
  if result < 1:
    result = 1

proc pgFlushOutgoing(db: PPGconn, deadline: int64): Future[void] {.async.} =
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
    if not await waitPgWritable(db, ms):
      cancelQuery(db)
      raise newException(DbError, "PostgreSQL query timeout")

proc pgAwaitReadyForGetResult(db: PPGconn, deadline: int64): Future[void] {.async.} =
  while true:
    if pqconsumeInput(db) != 1:
      dbError(db)
    if pqisBusy(db) != 1:
      return
    let ms = pgRemainingMs(deadline)
    if ms <= 0:
      cancelQuery(db)
      raise newException(DbError, "PostgreSQL query timeout")
    if not await waitPgReadable(db, ms):
      cancelQuery(db)
      raise newException(DbError, "PostgreSQL query timeout")

proc pgNextResult(db: PPGconn, deadline: int64): Future[PPGresult] {.async.} =
  await pgAwaitReadyForGetResult(db, deadline)
  result = pqgetResult(db)

proc pgEnsureIdle(db: PPGconn, deadline: int64): Future[void] {.async.} =
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

  let status =
    if pgParams.nParams > 0:
      pqsendQueryParams(db, query.cstring, pgParams.nParams, nil, pgParams.values, pgParams.lengths[0].unsafeAddr, pgParams.formats[0].unsafeAddr, 0)
    else:
      pqsendQueryParams(db, query.cstring, pgParams.nParams, nil, nil, nil, nil, 0)
  defer:
    if pgParams.nParams > 0: pgParams.values.deallocCStringArray()

  if status != 1: dbError(db)
  var dbRows: DbRows
  var rows = newSeq[Row]()
  let calledAt = getTime().toUnix()
  let deadline = calledAt + timeout.int64
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
      setColumnInfo(pqresult, dbRows, i, cols)
      rows.add(row)
    pqclear(pqresult)

  return (rows, dbRows)


proc exec*(db: PPGconn, query: string, args: JsonNode, columns: seq[Row], timeout: int) {.async.} =
  assert db.status == CONNECTION_OK
  let pgParams = PGParams.fromObjArray(args, columns)

  let status =
    if pgParams.nParams > 0:
      pqsendQueryParams(db, query.cstring, pgParams.nParams, nil, pgParams.values, pgParams.lengths[0].unsafeAddr, pgParams.formats[0].unsafeAddr, 0)
    else:
      pqsendQueryParams(db, query.cstring, pgParams.nParams, nil, nil, nil, nil, 0)
  defer:
    if pgParams.nParams > 0: pgParams.values.deallocCStringArray()

  if status != 1: dbError(db)
  let calledAt = getTime().toUnix()
  let deadline = calledAt + timeout.int64
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

  let status =
    if pgParams.nParams > 0:
      pqsendQueryParams(db, query.cstring, pgParams.nParams, nil, pgParams.values, pgParams.lengths[0].unsafeAddr, pgParams.formats[0].unsafeAddr, 0)
    else:
      pqsendQueryParams(db, query.cstring, pgParams.nParams, nil, nil, nil, nil, 0)
  defer:
    if pgParams.nParams > 0: pgParams.values.deallocCStringArray()

  if status != 1: dbError(db)
  var dbRows: DbRows
  var rows = newSeq[Row]()
  let calledAt = getTime().toUnix()
  let deadline = calledAt + timeout.int64
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
      setColumnInfo(pqresult, dbRows, i, cols)
      rows.add(row)
    pqclear(pqresult)

  return (rows, dbRows)


proc rawQuery*(db: PPGconn, query: string, args: JsonNode, timeout: int): Future[(seq[Row], DbRows)] {.async.} =
  assert db.status == CONNECTION_OK
  let pgParams = PGParams.fromArray(args)

  let status =
    if pgParams.nParams > 0:
      pqsendQueryParams(db, query.cstring, pgParams.nParams, nil, pgParams.values, pgParams.lengths[0].unsafeAddr, pgParams.formats[0].unsafeAddr, 0)
    else:
      pqsendQueryParams(db, query.cstring, pgParams.nParams, nil, nil, nil, nil, 0)
  defer:
    if pgParams.nParams > 0: pgParams.values.deallocCStringArray()

  if status != 1: dbError(db)
  var dbRows: DbRows
  var rows = newSeq[Row]()
  let calledAt = getTime().toUnix()
  let deadline = calledAt + timeout.int64
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
      setColumnInfo(pqresult, dbRows, i, cols)
      rows.add(row)
    pqclear(pqresult)

  return (rows, dbRows)


proc rawExec*(db: PPGconn, query: string, args: JsonNode, timeout: int) {.async.} =
  assert db.status == CONNECTION_OK
  let pgParams = PGParams.fromArray(args)

  let status =
    if pgParams.nParams > 0:
      pqsendQueryParams(db, query.cstring, pgParams.nParams, nil, pgParams.values, pgParams.lengths[0].unsafeAddr, pgParams.formats[0].unsafeAddr, 0)
    else:
      pqsendQueryParams(db, query.cstring, pgParams.nParams, nil, nil, nil, nil, 0)
  defer:
    if pgParams.nParams > 0: pgParams.values.deallocCStringArray()

  if status != 1: dbError(db)
  let calledAt = getTime().toUnix()
  let deadline = calledAt + timeout.int64
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
  let calledAt = getTime().toUnix()
  let deadline = calledAt + timeout.int64
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
      setColumnInfo(pqresult, dbRows, i, cols)
      rows.add(row)
    pqclear(pqresult)

  return (rows, dbRows)

proc queryPlain*(db: PPGconn, query: string, args: seq[string], timeout: int): Future[seq[Row]] {.async.} =
  assert db.status == CONNECTION_OK
  let status = pqsendQuery(db, dbFormat(query, args).cstring)
  if status != 1: dbError(db)
  var rows = newSeq[Row]()
  let calledAt = getTime().toUnix()
  let deadline = calledAt + timeout.int64
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
  let calledAt = getTime().toUnix()
  let deadline = calledAt + timeout.int64
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
  let calledAt = getTime().toUnix()
  let deadline = calledAt + timeout.int64
  await pgFlushOutgoing(db, deadline)
  while true:
    let pqresult = await pgNextResult(db, deadline)
    if pqresult == nil:
      db.checkError()
      break

    var cols = pqnfields(pqresult)
    setColumnInfo(pqresult, dbRows, 0, cols)
    pqclear(pqresult)

  for column in dbRows[0]:
    result.add(column.name)


proc prepare*(db: PPGconn, query: string, timeout: int, stmtName: string): Future[int] {.async.} =
  assert db.status == CONNECTION_OK
  let nArgs = query.count('$')
  let success = pqsendPrepare(db, stmtName, dbFormat(query).cstring, int32(nArgs), nil)
  if success != 1: dbError(db)
  let calledAt = getTime().toUnix()
  let deadline = calledAt + timeout.int64
  await pgFlushOutgoing(db, deadline)
  while true:
    let pqresult = await pgNextResult(db, deadline)
    if pqresult == nil:
      db.checkError()
      break
    pqclear(pqresult)
  return nArgs

proc preparedQuery*(db: PPGconn, args: seq[string], nArgs: int, timeout: int, stmtName: string): Future[(seq[Row], DbRows)] {.async.} =
  assert db.status == CONNECTION_OK
  let calledAt = getTime().toUnix()
  let deadline = calledAt + timeout.int64
  await pgEnsureIdle(db, deadline)
  let arr = allocCStringArray(args)
  let status = pqsendQueryPrepared(db, stmtName, int32(nArgs), arr, nil, nil, 0)
  deallocCStringArray(arr)
  if status != 1: dbError(db)
  var dbRows: DbRows
  var rows = newSeq[Row]()
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
      setColumnInfo(pqresult, dbRows, i, cols)
    pqclear(pqresult)

  return (rows, dbRows)

proc preparedExec*(db: PPGconn, args: seq[string], nArgs: int, timeout: int, stmtName: string) {.async.} =
  assert db.status == CONNECTION_OK
  let calledAt = getTime().toUnix()
  let deadline = calledAt + timeout.int64
  await pgEnsureIdle(db, deadline)
  let arr = allocCStringArray(args)
  let status = pqsendQueryPrepared(db, stmtName, int32(nArgs), arr, nil, nil, 0)
  deallocCStringArray(arr)
  if status != 1: dbError(db)
  await pgFlushOutgoing(db, deadline)
  while true:
    let pqresult = await pgNextResult(db, deadline)
    if pqresult == nil:
      db.checkError()
      break
    pqclear(pqresult)
