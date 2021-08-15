import times, asyncdispatch
import ../base
import ../rdb/mariadb
import ../libs/lib_mariadb

proc dbopen*(database: string = "", user: string = "", password: string = "", host: string = "", port: int32 = 0, maxConnections: int = 1, timeout=30): Connections =
  discard
  # let mariadb = mariadb.init(nil)
  # var pools = newSeq[Pool](maxConnections)
  # for i in 0..<maxConnections:
  #   while true:
  #     if conn == NET_ASYNC_NOT_READY: continue
  #     if conn == NET_ASYNC_ERROR: raise newException(Exception, "real_connect_start() failed")
  #     break
  #   pools[i] = Pool(
  #     mariadbConn: real_connect_start(mariadb, host, user, password, database, port, nil, 0),
  #     isBusy: false,
  #     createdAt: getTime().toUnix(),
  #   )
  # result = Connections(
  #   # driver: Driver.MariaDB,
  #   pools: pools,
  #   timeout: timeout
  # )

# proc query*(db:PMySQL, query: string, args: seq[string], timeout:int):Future[seq[base.Row]] {.async.} =
#   assert db.ping == 0
#   let query = dbFormat(query, args)
#   var status = real_query_nonblocking(db, query, query.len)
#   while status == NET_ASYNC_NOT_READY:
#     await sleepAsync(0)
#     status = real_query_nonblocking(db, query, query.len)
#   if status == NET_ASYNC_ERROR: dbError(db) # failed
#   var res: PRES
#   status = store_result_nonblocking(db, res.addr)
#   while status == NET_ASYNC_NOT_READY:
#     await sleepAsync(0)
#     status = store_result_nonblocking(db, res.addr)
#   if status == NET_ASYNC_ERROR: dbError(db)
#   if res == nil: dbError(db)
#   let L = num_fields(res)
#   var rows = newSeq[base.Row]()
#   let calledAt = getTime().toUnix()
#   while true:
#     if getTime().toUnix() >= calledAt + timeout:
#       dbError(db)
#     await sleepAsync(0)
#     var row: mysql.Row
#     status = fetch_row_nonblocking(res, row.addr)
#     while status != NET_ASYNC_COMPLETE:
#       await sleepAsync(0)
#       status = fetch_row_nonblocking(res, row.addr)
#     if row == nil: break
#     var baseRow = newSeq[string](L)
#     for i in 0..<L:
#       baseRow[i] = $row[i]
#     rows.add(baseRow)
#   var dbColumns: DbColumns
#   setColumnInfo(dbColumns, res, L)
#   return rows

# proc exec*(db:PMySQL, query: string, args: seq[string], timeout:int) {.async.} =
#   assert db.ping == 0
#   let query = dbFormat(query, args)
#   let success = send_query(db, query, query.len)
#   if success != 0: dbError(db) # never seen to fail when async
#   await sleepAsync(0)
#   let calledAt = getTime().toUnix()
#   while true:
#     if field_count(db) != 0:
#       let success = read_query_result(db)
#       if not success:
#         if getTime().toUnix() >= calledAt + timeout:
#           # キャンセル処理
#           # https://www.postgresql.jp/document/12.0/html/libpq-cancel.html
#           let res = rollback(db)
#           if not res:
#             raise newException(DbError, "failed to rollback")
#           return
#         await sleepAsync(10)
#         continue
#     var mysqlresult = use_result(db)
#     if mysqlresult == nil:
#       # Check if its a real error or just end of results
#       db.checkError()
#       break
#     free_result(mysqlresult)
