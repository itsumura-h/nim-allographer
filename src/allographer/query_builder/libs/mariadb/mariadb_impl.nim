import std/asyncdispatch
import std/times
import std/strutils
import std/strformat
import std/json
import ../../error
import ../../models/database_types
import ./mariadb_rdb
import ./mariadb_lib


proc rawExec(conn:PMySQL, query: string, args: seq[string]) =
  assert conn.ping() == 0

  var stmt = mariadb_rdb.stmt_init(conn)
  if stmt.isNil:
    mariadb_rdb.close(conn)
    dbError("mysql_stmt_init() failed")

  var q = dbFormat(query, args)
  if realQuery(conn, q.cstring, q.len) != 0'i32: dbError(conn)


proc rawExec(conn:PMySQL, query: string, args: MariadbParams) =
  assert conn.ping == 0

  var stmt = mariadb_rdb.stmt_init(conn)
  if stmt.isNil:
    mariadb_rdb.close(conn)
    dbError("mysql_stmt_init() failed")

  var q = dbFormat(conn, query, args)
  if realQuery(conn, q.cstring, q.len) != 0'i32: dbError(conn)


proc query*(db:PMySQL, query: string, args: seq[string], timeout:int):Future[(seq[database_types.Row], DbRows)] {.async.} =
  assert db.ping == 0
  var dbRows: DbRows
  var rows = newSeq[seq[string]]()
  var lines = 0

  rawExec(db, query, args)

  var sqlres = mariadb_rdb.useResult(db)
  let calledAt = getTime().toUnix()
  var dbColumns: DbColumns
  let cols = int(mariadb_rdb.numFields(sqlres))

  while true:
    if getTime().toUnix() >= calledAt + timeout:
      return
    await sleepAsync(0)
    var row: mariadb_rdb.Row
    var baseRow = newSeq[string](cols)
    setColumnInfo(dbColumns, sqlres, cols)
    row = mariadb_rdb.fetchRow(sqlres)
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
  var sqlres = mariadb_rdb.useResult(db)
  let calledAt = getTime().toUnix()
  let cols = int(mariadb_rdb.numFields(sqlres))
  while true:
    if getTime().toUnix() >= calledAt + timeout:
      return
    await sleepAsync(0)
    var row: mariadb_rdb.Row
    var baseRow = newSeq[string](cols)
    row = mariadb_rdb.fetchRow(sqlres)
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

  let params = MariadbParams.fromObj(args, columns)
  rawExec(db, query, params)


proc execGetValue*(db:PMySQL, query: string, args: JsonNode, columns:seq[seq[string]], timeout:int):Future[(seq[database_types.Row], DbRows)] {.async.} =
  assert db.ping == 0
  var dbRows: DbRows
  var rows = newSeq[seq[string]]()
  var lines = 0

  let params = MariadbParams.fromObj(args, columns)
  rawExec(db, query, params)

  var sqlres = mariadb_rdb.useResult(db)
  let calledAt = getTime().toUnix()
  var dbColumns: DbColumns
  let cols = int(mariadb_rdb.numFields(sqlres))

  while true:
    if getTime().toUnix() >= calledAt + timeout:
      return
    await sleepAsync(0)
    var row: mariadb_rdb.Row
    var baseRow = newSeq[string](cols)
    setColumnInfo(dbColumns, sqlres, cols)
    row = mariadb_rdb.fetchRow(sqlres)
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
  var sqlres = mariadb_rdb.useResult(db)
  let calledAt = getTime().toUnix()
  var dbColumns: DbColumns
  let cols = int(mariadb_rdb.numFields(sqlres))
  while true:
    if getTime().toUnix() >= calledAt + timeout:
      return
    await sleepAsync(0)
    var row: mariadb_rdb.Row
    setColumnInfo(dbColumns, sqlres, cols)
    for column in dbColumns:
      columns.add(column.name)
    row = mariadb_rdb.fetchRow(sqlres)
    break
  free_result(sqlres)
  return columns


proc getColumnTypes*(db:PMySQL, database, table:string, timeout:int):Future[seq[database_types.Row]] {.async.} =
  assert db.ping == 0

  let sql = &"SELECT `COLUMN_NAME`, `DATA_TYPE`  FROM `INFORMATION_SCHEMA`.`COLUMNS` WHERE TABLE_SCHEMA = '{database}' AND TABLE_NAME = '{table}'" 
  return queryPlain(db, sql, @[], timeout).await
