import times, asyncdispatch, strutils
import ../base
import ../rdb/postgres
import ../libs/lib_postgres

# https://www.postgresql.jp/document/12/html/libpq-async.html

proc dbopen*(database: string = "", user: string = "", password: string = "", host: string = "", port: int32 = 0, maxConnections: int = 1, timeout=30): Connections =
  var pools = newSeq[Pool](maxConnections)
  for i in 0..<maxConnections:
    let conn = postgres.pqsetdbLogin(host, $port, nil, nil, database, user, password)
    if pqStatus(conn) != CONNECTION_OK: dbError(conn)
    pools[i] = Pool(
      postgresConn: conn,
      isBusy: false,
      createdAt: getTime().toUnix(),
    )
  result = Connections(
    driver: PostgreSQL,
    pools: pools,
    timeout: timeout
  )

proc query*(db:PPGconn, query: string, args: seq[string], timeout:int):Future[(seq[Row], DbRows)] {.async.} =
  assert db.status == CONNECTION_OK
  let status = pqsendQuery(db, dbFormat(query, args))
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
        let res = pqCancel(cancel, err, 0)
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

proc exec*(db:PPGconn, query: string, args: seq[string], timeout:int) {.async.} =
  assert db.status == CONNECTION_OK
  let success = pqsendQuery(db, dbFormat(query, args))
  if success != 1: dbError(db)
  let calledAt = getTime().toUnix()
  await sleepAsync(0)
  while true:
    let success = pqconsumeInput(db)
    if success != 1: dbError(db) # never seen to fail when async
    if pqisBusy(db) == 1:
      if getTime().toUnix() >= calledAt + timeout:
        let cancel = pqGetCancel(db)
        var err = ""
        let res = pqCancel(cancel, err, 0)
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

proc prepare*(db:PPGconn, query: string, timeout:int, stmtName:string):Future[int] {.async.} =
  assert db.status == CONNECTION_OK
  let nArgs = query.count('$')
  let success = pqsendPrepare(db, stmtName, dbFormat(query), int32(nArgs), nil)
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
        let res = pqCancel(cancel, err, 0)
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
        let res = pqCancel(cancel, err, 0)
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
