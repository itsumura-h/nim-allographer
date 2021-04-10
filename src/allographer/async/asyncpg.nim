import asyncdispatch, json, times, options
include db_postgres
import ../connection

type
  ## db pool
  AsyncPool* = ref object
    conns*: seq[DbConn]
    busy*: seq[bool]

  ## Excpetion to catch on errors
  PGError* = object of Exception


proc newAsyncPool*(
    connection,
    user,
    password,
    database: string,
    num: int
  ): AsyncPool =
  ## Create a new async pool of num connections.
  result = AsyncPool()
  result.busy = newSeq[bool](num)
  for i in 0..<num:
    let conn = open(connection, user, password, database)
    assert conn.status == CONNECTION_OK
    result.conns.add(conn)

proc getFreeConnIdx*(pool: AsyncPool): Future[int] {.async.} =
  ## Wait for a free connection and return it.
  while true:
    for conIdx in 0..<pool.conns.len:
      if not pool.busy[conIdx]:
        pool.busy[conIdx] = true
        return conIdx
    await sleepAsync(10)

proc returnConn*(pool: AsyncPool, conIdx: int) =
  ## Make the connection as free after using it and getting results.
  pool.busy[conIdx] = false

proc getColumns(db_columns:DbColumns):seq[array[3, string]] =
  var columns = newSeq[array[3, string]](db_columns.len)
  for i, row in db_columns:
    columns[i] = [row.name, $row.typ.kind, $row.typ.size]
  return columns

proc toJson(results:openArray[seq[string]], columns:openArray[array[3, string]]):seq[JsonNode] =
  var response_table = newSeq[JsonNode](results.len)
  for index, rows in results.pairs:
    var response_row = newJObject()
    for i, row in rows:
      let key = columns[i][0]
      let typ = columns[i][1]
      let size = columns[i][2]

      if row == "":
        response_row[key] = newJNull()
      elif [$dbInt, $dbUInt].contains(typ):
        response_row[key] = newJInt(row.parseInt)
      elif [$dbDecimal, $dbFloat].contains(typ):
        response_row[key] = newJFloat(row.parseFloat)
      elif [$dbBool].contains(typ):
        if row == "f":
          response_row[key] = newJBool(false)
        elif row == "t":
          response_row[key] = newJBool(true)
      elif [$dbJson].contains(typ):
        response_row[key] = row.parseJson
      else:
        response_row[key] = newJString(row)

    response_table[index] = response_row
  return response_table

proc checkError(db: DbConn) =
  ## Raises a DbError exception.
  var message = pqErrorMessage(db)
  if message.len > 0:
    raise newException(PGError, $message)


# ==================================================
proc asyncGetAllRows(db: DbConn, query: SqlQuery, args: seq[string]):Future[seq[JsonNode]] {.async.} =
  assert db.status == CONNECTION_OK
  let success = pqsendQuery(db, dbFormat(query, args))
  if success != 1: dbError(db) # never seen to fail when async
  var db_columns: DbColumns
  var rows = newSeq[Row]()
  while true:
    let success = pqconsumeInput(db)
    if success != 1: dbError(db) # never seen to fail when async
    if pqisBusy(db) == 1:
      await sleepAsync(1)
      continue
    var pqresult = pqgetResult(db)
    if pqresult == nil:
      # Check if its a real error or just end of results
      db.checkError()
      break
    setColumnInfo(db_columns, pqresult, pqnfields(pqresult))
    var cols = pqnfields(pqresult)
    var row = newRow(cols)
    for i in 0'i32..pqNtuples(pqresult)-1:
      setRow(pqresult, row, i, cols)
      rows.add row
    pqclear(pqresult)
  let columns = getColumns(db_columns)
  return toJson(rows, columns)

proc asyncGetAllRows*(pool: AsyncPool,
                      sqlString: string,
                      args: seq[string]
  ): Future[seq[JsonNode]] {.async.} =
    let conIdx = await pool.getFreeConnIdx()
    result = await asyncGetAllRows(pool.conns[conIdx], sql sqlString, args)
    pool.returnConn(conIdx)


proc asyncGetRow(db: DbConn, query: SqlQuery, args: seq[string]):Future[Option[JsonNode]] {.async.} =
  assert db.status == CONNECTION_OK
  let success = pqsendQuery(db, dbFormat(query, args))
  if success != 1: dbError(db) # never seen to fail when async
  var db_columns: DbColumns
  var rows = newSeq[Row]()
  while true:
    let success = pqconsumeInput(db)
    if success != 1: dbError(db) # never seen to fail when async
    if pqisBusy(db) == 1:
      await sleepAsync(1)
      continue
    var pqresult = pqgetResult(db)
    if pqresult == nil:
      # Check if its a real error or just end of results
      db.checkError()
      break
    setColumnInfo(db_columns, pqresult, pqnfields(pqresult))
    var cols = pqnfields(pqresult)
    var row = newRow(cols)
    for i in 0'i32..pqNtuples(pqresult)-1:
      setRow(pqresult, row, i, cols)
      rows.add(row)
    pqclear(pqresult)

  if rows.len == 0:
    return none(JsonNode)

  let columns = getColumns(db_columns)
  return toJson(rows, columns)[0].some

proc asyncGetRow*(pool:AsyncPool,
                    sqlString:string,
                    args:seq[string]
  ):Future[Option[JsonNode]] {.async.} =
    let conIdx = await pool.getFreeConnIdx()
    result = await asyncGetRow(pool.conns[conIdx], sql sqlString, args)
    pool.returnConn(conIdx)

proc asyncGetAllRowsPlain(db: DbConn, query: SqlQuery, args: seq[string]):Future[seq[Row]] {.async.} =
  assert db.status == CONNECTION_OK
  let success = pqsendQuery(db, dbFormat(query, args))
  if success != 1: dbError(db) # never seen to fail when async
  while true:
    let success = pqconsumeInput(db)
    if success != 1: dbError(db) # never seen to fail when async
    if pqisBusy(db) == 1:
      await sleepAsync(1)
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
      result.add row
    pqclear(pqresult)

proc asyncGetAllRowsPlain*(pool:AsyncPool,
                          sqlString:string,
                          args:seq[string]
  ):Future[seq[Row]] {.async.} =
    let conIdx = await pool.getFreeConnIdx()
    result = await asyncGetAllRowsPlain(pool.conns[conIdx], sql sqlString, args)
    pool.returnConn(conIdx)


proc asyncGetRowPlain(db: DbConn, query: SqlQuery, args: seq[string]):Future[Row] {.async.} =
  assert db.status == CONNECTION_OK
  let success = pqsendQuery(db, dbFormat(query, args))
  if success != 1: dbError(db) # never seen to fail when async
  while true:
    let success = pqconsumeInput(db)
    if success != 1: dbError(db) # never seen to fail when async
    if pqisBusy(db) == 1:
      await sleepAsync(1)
      continue
    var pqresult = pqgetResult(db)
    if pqresult == nil:
      # Check if its a real error or just end of results
      db.checkError()
      break
    var cols = pqnfields(pqresult)
    var row = newRow(cols)
    setRow(pqresult, row, 0, cols)
    result.add(row)
    pqclear(pqresult)


proc asyncGetRowPlain*(pool:AsyncPool,
                        sqlString:string,
                        args:seq[string]
):Future[Row] {.async.} =
  let conIdx = await pool.getFreeConnIdx()
  result = await asyncGetRowPlain(pool.conns[conIdx], sql sqlString, args)
  pool.returnConn(conIdx)


proc asyncExec(db: DbConn, query: SqlQuery, args: seq[string]) {.async.} =
  assert db.status == CONNECTION_OK
  let success = pqsendQuery(db, dbFormat(query, args))
  if success != 1: dbError(db)
  while true:
    let success = pqconsumeInput(db)
    if success != 1: dbError(db) # never seen to fail when async
    if pqisBusy(db) == 1:
      await sleepAsync(1)
      continue
    var pqresult = pqgetResult(db)
    if pqresult == nil:
      # Check if its a real error or just end of results
      db.checkError()
      break
    pqclear(pqresult)

proc asyncExec*(pool:AsyncPool,
                  sqlString:string,
                  args:seq[string]
) {.async.} =
  let conIdx = await pool.getFreeConnIdx()
  await asyncExec(pool.conns[conIdx], sql sqlString, args)
  pool.returnConn(conIdx)
