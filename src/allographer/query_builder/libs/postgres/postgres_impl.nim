## https://www.postgresql.jp/document/12/html/libpq-async.html

import std/asyncdispatch
import std/json
import std/strutils
import std/times
import ../../error
import ../../models/database_types
import ./postgres_rdb
import ./postgres_lib


proc query*(db:PPGconn, query: string, args: JsonNode, timeout:int):Future[(seq[Row], DbRows)] {.async.} =
  assert db.status == CONNECTION_OK
  let pgParams = PGParams.fromObjArray(args)

  let status =
    if pgParams.nParams > 0:
      pqsendQueryParams(db, query.cstring, pgParams.nParams, nil, pgParams.values, pgParams.lengths[0].unsafeAddr, pgParams.formats[0].unsafeAddr, 0)
    else:
      pqsendQueryParams(db, query.cstring, pgParams.nParams, nil, nil, nil, nil, 0)
  defer:
    if pgParams.nParams > 0: pgParams.values.deallocCStringArray()

  if status != 1: dbError(db) # never seen to fail when async
  var dbRows: DbRows
  var rows = newSeq[Row]()
  let calledAt = getTime().toUnix()
  # sleepAsync(0).await
  while true:
    let success = pqconsumeInput(db)
    if success != 1: dbError(db) # never seen to fail when async
    if pqisBusy(db) == 1:
      if getTime().toUnix() >= calledAt + timeout:
        # exec cancel
        # https://www.postgresql.jp/document/12.0/html/libpq-cancel.html
        let cancel = pqGetCancel(db)
        var err = ""
        let res = pqCancel(cancel, err.cstring, 0)
        if res == 0:
          raise newException(DbError, err)
        return
      await sleepAsync(10)
      continue
    var pqresult = pqgetResult(db)
    if pqresult == nil:
      # Check if its a real error or just end of results
      db.checkError()
      break

    var cols = pqnfields(pqresult)
    var row = newRow(cols)
    for i in 0'i32..pqNtuples(pqresult)-1:
      setRow(pqresult, row, i, cols)
      setColumnInfo(pqresult, dbRows, i, cols)
      rows.add(row)
    pqclear(pqresult)

  return (rows, dbRows)


proc exec*(db:PPGconn, query: string, args: JsonNode, columns:seq[Row], timeout:int) {.async.} =
  assert db.status == CONNECTION_OK
  let pgParams = PGParams.fromObjArray(args, columns)

  let status =
    if pgParams.nParams > 0:
      pqsendQueryParams(db, query.cstring, pgParams.nParams, nil, pgParams.values, pgParams.lengths[0].unsafeAddr, pgParams.formats[0].unsafeAddr, 0)
    else:
      pqsendQueryParams(db, query.cstring, pgParams.nParams, nil, nil, nil, nil, 0)
  defer:
    if pgParams.nParams > 0: pgParams.values.deallocCStringArray()

  if status != 1: dbError(db) # never seen to fail when async
  let calledAt = getTime().toUnix()
  # await sleepAsync(0)
  while true:
    let success = pqconsumeInput(db)
    if success != 1: dbError(db) # never seen to fail when async
    if pqisBusy(db) == 1:
      if getTime().toUnix() >= calledAt + timeout:
        # exec cancel
        # https://www.postgresql.jp/document/12.0/html/libpq-cancel.html
        let cancel = pqGetCancel(db)
        var err = ""
        let res = pqCancel(cancel, err.cstring, 0)
        if res == 0:
          raise newException(DbError, err)
        return
      await sleepAsync(10)
      continue
    var pqresult = pqgetResult(db)
    if pqresult == nil:
      # Check if its a real error or just end of results
      db.checkError()
      break


proc execGetValue*(db:PPGconn, query: string, args: JsonNode, columns:seq[Row], timeout:int):Future[(seq[Row], DbRows)] {.async.} =
  assert db.status == CONNECTION_OK
  let pgParams = PGParams.fromObjArray(args, columns)

  let status =
    if pgParams.nParams > 0:
      pqsendQueryParams(db, query.cstring, pgParams.nParams, nil, pgParams.values, pgParams.lengths[0].unsafeAddr, pgParams.formats[0].unsafeAddr, 0)
    else:
      pqsendQueryParams(db, query.cstring, pgParams.nParams, nil, nil, nil, nil, 0)
  defer:
    if pgParams.nParams > 0: pgParams.values.deallocCStringArray()

  if status != 1: dbError(db) # never seen to fail when async
  var dbRows: DbRows
  var rows = newSeq[Row]()
  let calledAt = getTime().toUnix()
  # await sleepAsync(0)
  while true:
    let success = pqconsumeInput(db)
    if success != 1: dbError(db) # never seen to fail when async
    if pqisBusy(db) == 1:
      if getTime().toUnix() >= calledAt + timeout:
        # exec cancel
        # https://www.postgresql.jp/document/12.0/html/libpq-cancel.html
        let cancel = pqGetCancel(db)
        var err = ""
        let res = pqCancel(cancel, err.cstring, 0)
        if res == 0:
          raise newException(DbError, err)
        return
      await sleepAsync(10)
      continue
    var pqresult = pqgetResult(db)
    if pqresult == nil:
      # Check if its a real error or just end of results
      db.checkError()
      break

    var cols = pqnfields(pqresult)
    var row = newRow(cols)
    for i in 0'i32..pqNtuples(pqresult)-1:
      setRow(pqresult, row, i, cols)
      setColumnInfo(pqresult, dbRows, i, cols)
      rows.add(row)
    pqclear(pqresult)

  return (rows, dbRows)


proc rawQuery*(db:PPGconn, query: string, args: JsonNode, timeout:int):Future[(seq[Row], DbRows)] {.async.} =
  assert db.status == CONNECTION_OK
  let pgParams = PGParams.fromArray(args)

  let status =
    if pgParams.nParams > 0:
      pqsendQueryParams(db, query.cstring, pgParams.nParams, nil, pgParams.values, pgParams.lengths[0].unsafeAddr, pgParams.formats[0].unsafeAddr, 0)
    else:
      pqsendQueryParams(db, query.cstring, pgParams.nParams, nil, nil, nil, nil, 0)
  defer:
    if pgParams.nParams > 0: pgParams.values.deallocCStringArray()

  if status != 1: dbError(db) # never seen to fail when async
  var dbRows: DbRows
  var rows = newSeq[Row]()
  let calledAt = getTime().toUnix()
  # await sleepAsync(0)
  while true:
    let success = pqconsumeInput(db)
    if success != 1: dbError(db) # never seen to fail when async
    if pqisBusy(db) == 1:
      if getTime().toUnix() >= calledAt + timeout:
        # exec cancel
        # https://www.postgresql.jp/document/12.0/html/libpq-cancel.html
        let cancel = pqGetCancel(db)
        var err = ""
        let res = pqCancel(cancel, err.cstring, 0)
        if res == 0:
          raise newException(DbError, err)
        return
      await sleepAsync(10)
      continue
    var pqresult = pqgetResult(db)
    if pqresult == nil:
      # Check if its a real error or just end of results
      db.checkError()
      break

    var cols = pqnfields(pqresult)
    var row = newRow(cols)
    for i in 0'i32..pqNtuples(pqresult)-1:
      setRow(pqresult, row, i, cols)
      setColumnInfo(pqresult, dbRows, i, cols)
      rows.add(row)
    pqclear(pqresult)

  return (rows, dbRows)


proc rawExec*(db:PPGconn, query: string, args: JsonNode, timeout:int) {.async.} =
  ## used by raw().exec()
  assert db.status == CONNECTION_OK
  let pgParams = PGParams.fromArray(args)

  let status =
    if pgParams.nParams > 0:
      pqsendQueryParams(db, query.cstring, pgParams.nParams, nil, pgParams.values, pgParams.lengths[0].unsafeAddr, pgParams.formats[0].unsafeAddr, 0)
    else:
      pqsendQueryParams(db, query.cstring, pgParams.nParams, nil, nil, nil, nil, 0)
  defer:
    if pgParams.nParams > 0: pgParams.values.deallocCStringArray()

  if status != 1: dbError(db) # never seen to fail when async
  let calledAt = getTime().toUnix()
  # sleepAsync(0).await
  while true:
    let success = pqconsumeInput(db)
    if success != 1: dbError(db) # never seen to fail when async
    if pqisBusy(db) == 1:
      if getTime().toUnix() >= calledAt + timeout:
        # exec cancel
        # https://www.postgresql.jp/document/12.0/html/libpq-cancel.html
        let cancel = pqGetCancel(db)
        var err = ""
        let res = pqCancel(cancel, err.cstring, 0)
        if res == 0:
          raise newException(DbError, err)
        return
      await sleepAsync(10)
      continue
    var pqresult = pqgetResult(db)
    if pqresult == nil:
      # Check if its a real error or just end of results
      db.checkError()
      break


# ==================================================
# Old functions
# ==================================================

proc query*(db:PPGconn, query: string, args: seq[string], timeout:int):Future[(seq[Row], DbRows)] {.async.} =
  assert db.status == CONNECTION_OK
  let status = pqsendQuery(db, dbFormat(query, args).cstring)
  if status != 1: dbError(db) # never seen to fail when async
  var dbRows: DbRows
  var rows = newSeq[Row]()
  let calledAt = getTime().toUnix()
  await sleepAsync(0)
  while true:
    let success = pqconsumeInput(db)
    if success != 1: dbError(db) # never seen to fail when async
    if pqisBusy(db) == 1:
      if getTime().toUnix() >= calledAt + timeout:
        # exec cancel
        # https://www.postgresql.jp/document/12.0/html/libpq-cancel.html
        let cancel = pqGetCancel(db)
        var err = ""
        let res = pqCancel(cancel, err.cstring, 0)
        if res == 0:
          raise newException(DbError, err)
        return
      await sleepAsync(10)
      continue
    var pqresult = pqgetResult(db)
    if pqresult == nil:
      # Check if its a real error or just end of results
      db.checkError()
      break

    var cols = pqnfields(pqresult)
    var row = newRow(cols)
    for i in 0'i32..pqNtuples(pqresult)-1:
      setRow(pqresult, row, i, cols)
      setColumnInfo(pqresult, dbRows, i, cols)
      rows.add(row)
    pqclear(pqresult)

  return (rows, dbRows)

proc queryPlain*(db:PPGconn, query: string, args: seq[string], timeout:int):Future[seq[Row]] {.async.} =
  assert db.status == CONNECTION_OK
  let status = pqsendQuery(db, dbFormat(query, args).cstring)
  if status != 1: dbError(db) # never seen to fail when async
  var rows = newSeq[Row]()
  let calledAt = getTime().toUnix()
  # await sleepAsync(0)
  while true:
    let success = pqconsumeInput(db)
    if success != 1: dbError(db) # never seen to fail when async
    if pqisBusy(db) == 1:
      if getTime().toUnix() >= calledAt + timeout:
        # exec cancel
        # https://www.postgresql.jp/document/12.0/html/libpq-cancel.html
        let cancel = pqGetCancel(db)
        var err = ""
        let res = pqCancel(cancel, err.cstring, 0)
        if res == 0:
          raise newException(DbError, err)
        return
      await sleepAsync(10)
      continue
    var pqresult = pqgetResult(db)
    if pqresult == nil:
      # Check if its a real error or just end of results
      db.checkError()
      break

    var cols = pqnfields(pqresult)
    var row = newRow(cols)
    for i in 0'i32..pqNtuples(pqresult)-1:
      setRow(pqresult, row, i, cols)
      rows.add(row)
    pqclear(pqresult)

  return rows


proc exec*(db:PPGconn, query: string, args: seq[string], timeout:int) {.async.} =
  assert db.status == CONNECTION_OK
  let success = pqsendQuery(db, dbFormat(query, args).cstring)
  if success != 1: dbError(db)
  let calledAt = getTime().toUnix()
  # await sleepAsync(0)
  while true:
    let success = pqconsumeInput(db)
    if success != 1: dbError(db) # never seen to fail when async
    if pqisBusy(db) == 1:
      if getTime().toUnix() >= calledAt + timeout:
        let cancel = pqGetCancel(db)
        var err = ""
        let res = pqCancel(cancel, err.cstring, 0)
        if res == 0:
          raise newException(DbError, err)
        return
      await sleepAsync(10)
      continue
    var pqresult = pqgetResult(db)
    if pqresult == nil:
      # Check if its a real error or just end of results
      db.checkError()
      break
    pqclear(pqresult)


proc getColumns*(db:PPGconn, query: string, args: seq[string], timeout:int):Future[seq[string]] {.async.} =
  assert db.status == CONNECTION_OK
  let status = pqsendQuery(db, dbFormat(query, args).cstring)
  if status != 1: dbError(db) # never seen to fail when async
  var dbRows: DbRows
  let calledAt = getTime().toUnix()
  # await sleepAsync(0)
  while true:
    let success = pqconsumeInput(db)
    if success != 1: dbError(db) # never seen to fail when async
    if pqisBusy(db) == 1:
      if getTime().toUnix() >= calledAt + timeout:
        # exec cancel
        # https://www.postgresql.jp/document/12.0/html/libpq-cancel.html
        let cancel = pqGetCancel(db)
        var err = ""
        let res = pqCancel(cancel, err.cstring, 0)
        if res == 0:
          raise newException(DbError, err)
        return
      await sleepAsync(10)
      continue
    var pqresult = pqgetResult(db)
    if pqresult == nil:
      # Check if its a real error or just end of results
      db.checkError()
      break

    var cols = pqnfields(pqresult)
    setColumnInfo(pqresult, dbRows, 0, cols)
    pqclear(pqresult)

  for column in dbRows[0]:
    result.add(column.name)


proc prepare*(db:PPGconn, query: string, timeout:int, stmtName:string):Future[int] {.async.} =
  assert db.status == CONNECTION_OK
  let nArgs = query.count('$')
  let success = pqsendPrepare(db, stmtName, dbFormat(query).cstring, int32(nArgs), nil)
  if success != 1: dbError(db)
  while true:
    var pqresult = pqgetResult(db)
    if pqresult == nil:
      # Check if its a real error or just end of results
      db.checkError()
      break
    pqclear(pqresult)
  return nArgs

proc preparedQuery*(db:PPGconn, args: seq[string], nArgs:int, timeout:int, stmtName:string):Future[(seq[Row], DbRows)] {.async.} =
  assert db.status == CONNECTION_OK
  while pqisBusy(db) == 1:
    await sleepAsync(10)
  let arr = allocCStringArray(args)
  let status = pqsendQueryPrepared(db, stmtName, int32(nArgs), arr, nil, nil, 0)
  deallocCStringArray(arr)
  if status != 1: dbError(db) # never seen to fail when async
  var dbRows: DbRows
  var rows = newSeq[Row]()
  let calledAt = getTime().toUnix()
  while true:
    await sleepAsync(0)
    let success = pqconsumeInput(db)
    if success != 1: dbError(db) # never seen to fail when async
    if pqisBusy(db) == 1:
      if getTime().toUnix() >= calledAt + timeout:
        # exec cancel
        # https://www.postgresql.jp/document/12.0/html/libpq-cancel.html
        let cancel = pqGetCancel(db)
        var err = ""
        let res = pqCancel(cancel, err.cstring, 0)
        if res == 0:
          raise newException(DbError, err)
        return
      await sleepAsync(10)
      continue
    var pqresult = pqgetResult(db)
    if pqresult == nil:
      # Check if its a real error or just end of results
      db.checkError()
      break

    var cols = pqnfields(pqresult)
    var row = newRow(cols)
    for i in 0'i32..pqNtuples(pqresult)-1:
      setRow(pqresult, row, i, cols)
      rows.add(row)
      setColumnInfo(pqresult, dbRows, i, cols)
    pqclear(pqresult)

  return (rows, dbRows)

proc preparedExec*(db:PPGconn, args: seq[string], nArgs:int, timeout:int, stmtName:string) {.async.} =
  assert db.status == CONNECTION_OK
  while pqisBusy(db) == 1:
    await sleepAsync(10)
  let arr = allocCStringArray(args)
  let status = pqsendQueryPrepared(db, stmtName, int32(nArgs), arr, nil, nil, 0)
  deallocCStringArray(arr)
  if status != 1: dbError(db) # never seen to fail when async
  let calledAt = getTime().toUnix()
  while true:
    await sleepAsync(0)
    let success = pqconsumeInput(db)
    if success != 1: dbError(db) # never seen to fail when async
    if pqisBusy(db) == 1:
      if getTime().toUnix() >= calledAt + timeout:
        # exec cancel
        # https://www.postgresql.jp/document/12.0/html/libpq-cancel.html
        let cancel = pqGetCancel(db)
        var err = ""
        let res = pqCancel(cancel, err.cstring, 0)
        if res == 0:
          raise newException(DbError, err)
        return
      await sleepAsync(10)
      continue
    var pqresult = pqgetResult(db)
    if pqresult == nil:
      # Check if its a real error or just end of results
      db.checkError()
      break
    pqclear(pqresult)
