import std/asyncdispatch
import std/times
import std/strutils
import std/json
import ../../error
import ../../models/database_types
import ./mariadb_rdb
import ./mariadb_lib


# proc dbopen*(database: string = "", user: string = "", password: string = "", host: string = "", port: int32 = 0, maxConnections: int = 1, timeout=30): Connections =
#   var pools = newSeq[Pool](maxConnections)
#   for i in 0..<maxConnections:
#     var res = mariadb_rdb.init(nil)
#     if res == nil:
#       dbError("could not open database connection")
#     if mariadb_rdb.realConnect(res, host, user, password, database, port, nil, 0) == nil:
#       var errmsg = $mariadb_rdb.error(res)
#       mariadb_rdb.close(res)
#       dbError(errmsg)
#     pools[i] = Pool(
#       mariadbConn: res,
#       isBusy: false,
#       createdAt: getTime().toUnix(),
#     )
#   result = Connections(
#     pools: pools,
#     timeout: timeout
#   )

proc rawExec*(conn:PMySQL, query: string, args: JsonNode, timeout:int) {.async.} =
  ## args is `JArray`
  assert conn.ping == 0
  let query = query.strip.cstring

  var stmt = mariadb_rdb.stmt_init(conn)
  if stmt.isNil:
    mariadb_rdb.close(conn)
    dbError("mysql_stmt_init() failed")

  if mariadb_rdb.stmt_prepare(stmt, query, query.len) != 0:
    discard mariadb_rdb.stmt_close(stmt)
    mariadb_rdb.close(conn)
    dbError("mysql_stmt_prepare() failed")

  let mariaParams = MariadbParams.fromArray(args)
  
  if args.len > 0:
    var bindParams = newSeq[BIND](args.len)
    for i in 0..<mariaParams.nParams:
      case mariaParams.buffer[i].kind
      of JBool:
        discard
      of JInt:
        let param = BIND(
          length: mariaParams.len[i].unsafeAddr,
          is_null: mariaParams.isNull[i].unsafeAddr,
          buffer: mariaParams.buffer[i].intBuffer.unsafeAddr,
          buffer_type: mariaParams.bufferType[i],
          buffer_length: mariaParams.bufferlength[i],
        )
        bindParams[i] = param
      of JFloat:
        discard
      of JArray, JObject:
        discard
      of JNull:
        discard
      of JString:
        let param = BIND(
          length: mariaParams.len[i].unsafeAddr,
          is_null: mariaParams.isNull[i].unsafeAddr,
          buffer: mariaParams.buffer[i].stringBuffer.unsafeAddr,
          buffer_type: mariaParams.bufferType[i],
          buffer_length: mariaParams.bufferlength[i],
        )
        bindParams[i] = param

    echo ""
    echo bindParams.repr
    echo ""

    echo "==== stmt_bind_param"
    if mariadb_rdb.stmt_bind_param(stmt, bindParams[0].unsafeAddr):
      echo "stmt_error: ",stmt.stmt_error()
      echo "stmt_errno: ",stmt.stmt_errno() 
      echo "error: ",conn.error()
      echo "errno: ",conn.errno()
      discard mariadb_rdb.stmt_close(stmt)
      mariadb_rdb.close(conn)
      dbError("mysql_stmt_bind_param() failed")
    else:
      echo "stmt_error: ",stmt.stmt_error()
      echo "stmt_errno: ",stmt.stmt_errno()
      echo "error: ",conn.error()
      echo "errno: ",conn.errno()

  echo "stmt_param_count: ", mariadb_rdb.stmt_param_count(stmt)

  echo "stmt.isNil: ",stmt.isNil
  echo "==== stmt_execute start"
  if mariadb_rdb.stmt_execute(stmt) != 0:
    echo "stmt_error: ",stmt.stmt_error()
    echo "error: ",conn.error()
    echo "errno: ",conn.errno()
    discard mariadb_rdb.stmt_close(stmt)
    mariadb_rdb.close(conn)
    dbError("mysql_stmt_execute() failed")
  echo "==== stmt_execute end"

  # discard bindParams.repr



# proc query*(db:PMySQL, query: string, args: seq[string], timeout:int):Future[(seq[database_types.Row], DbRows)] {.async.} =
#   assert db.ping == 0
#   var dbRows: DbRows
#   var rows = newSeq[seq[string]]()
#   var lines = 0

#   rawExec(db, query, args)
#   var sqlres = mariadb_rdb.useResult(db)
#   let calledAt = getTime().toUnix()
#   var dbColumns: DbColumns
#   let cols = int(mariadb_rdb.numFields(sqlres))
#   while true:
#     if getTime().toUnix() >= calledAt + timeout:
#       return
#     await sleepAsync(0)
#     var row: mariadb_rdb.Row
#     var baseRow = newSeq[string](cols)
#     setColumnInfo(dbColumns, sqlres, cols)
#     row = mariadb_rdb.fetchRow(sqlres)
#     if row == nil: break
#     for i in 0..<cols:
#       if row[i].isNil:
#         dbColumns[i].typ.kind = dbNull
#       baseRow[i] = $row[i]
#     rows.add(baseRow)
#     dbRows.add(dbColumns)
#     lines.inc()
#   free_result(sqlres)
#   return (rows, dbRows)


# proc queryPlain*(db:PMySQL, query: string, args: seq[string], timeout:int):Future[seq[database_types.Row]] {.async.} =
#   assert db.ping == 0
#   rawExec(db, query, args)
#   var rows = newSeq[seq[string]]()
#   var sqlres = mariadb_rdb.useResult(db)
#   let calledAt = getTime().toUnix()
#   let cols = int(mariadb_rdb.numFields(sqlres))
#   while true:
#     if getTime().toUnix() >= calledAt + timeout:
#       return
#     await sleepAsync(0)
#     var row: mariadb_rdb.Row
#     var baseRow = newSeq[string](cols)
#     row = mariadb_rdb.fetchRow(sqlres)
#     if row == nil: break
#     for i in 0..<cols:
#       baseRow[i] = $row[i]
#     rows.add(baseRow)
#   free_result(sqlres)
#   return rows


# proc exec*(db:PMySQL, query: string, args: seq[string], timeout:int) {.async.} =
#   var q = dbFormat(query, args)
#   await sleepAsync(0)
#   if realQuery(db, q.cstring, q.len) != 0'i32: dbError(db)


# proc getColumns*(db:PMySQL, query: string, args: seq[string], timeout:int):Future[seq[string]] {.async.} =
#   assert db.ping == 0
#   var columns:seq[string]
  
#   rawExec(db, query, args)
#   var sqlres = mariadb_rdb.useResult(db)
#   let calledAt = getTime().toUnix()
#   var dbColumns: DbColumns
#   let cols = int(mariadb_rdb.numFields(sqlres))
#   while true:
#     if getTime().toUnix() >= calledAt + timeout:
#       return
#     await sleepAsync(0)
#     var row: mariadb_rdb.Row
#     setColumnInfo(dbColumns, sqlres, cols)
#     for column in dbColumns:
#       columns.add(column.name)
#     row = mariadb_rdb.fetchRow(sqlres)
#     break
#   free_result(sqlres)
#   return columns
