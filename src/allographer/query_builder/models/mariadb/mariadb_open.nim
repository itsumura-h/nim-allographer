import std/times
import ../../../env
import ../../error
import ../../libs/mariadb/mariadb_rdb
import ../../libs/mariadb/mariadb_lib
import ./mariadb_types


proc mariadbOpen*(database: string = "", user: string = "", password: string = "", host: string = "", port: int32 = 0, maxConnections: int = 1, timeout=30): MariadbConnections =
  var pools = newSeq[MariadbConnection](maxConnections)
  for i in 0..<maxConnections:
    let conn = mariadb_rdb.init(nil)
    if conn == nil:
      mariadb_rdb.close(conn)
      dbError("mysql_init() failed")
    if mariadb_rdb.realConnect(conn, host, user, password, database, port, nil, 0) == nil:
      # var errmsg = $mariadb_rdb.error(conn)
      mariadb_rdb.close(conn)
      dbError("mysql_real_connect_start() failed")
    pools[i] = MariadbConnection(
      conn: conn,
      isBusy: false,
      createdAt: getTime().toUnix(),
    )
  result = MariadbConnections(
    pools: pools,
    timeout: timeout
  )
