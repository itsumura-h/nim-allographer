import std/times
# import ../../../env
import ../../error
import ../../libs/mysql/mysql_rdb
import ./mysql_types


proc mysqlOpen*(database: string = "", user: string = "", password: string = "", host: string = "", port: int32 = 0, maxConnections: int = 1, timeout=30): MysqlConnections =
  var pools = newSeq[MysqlConnection](maxConnections)
  for i in 0..<maxConnections:
    let conn = mysql_rdb.init(nil)
    if conn == nil:
      mysql_rdb.close(conn)
      dbError("mysql_rdb.init() failed")
    if mysql_rdb.real_connect(conn, host, user, password, database, port, nil, 0) == nil:
      var errmsg = $mysql_rdb.error(conn)
      mysql_rdb.close(conn)
      dbError(errmsg)
    pools[i] = MysqlConnection(
      conn: conn,
      isBusy: false,
      createdAt: getTime().toUnix()
    )
  let info = MysqlConnectionInfo(
    database:database,
    user:user,
    password:password,
    host:host,
    port:port
  )
  result = MysqlConnections(
    pools: pools,
    timeout: timeout,
    info: info
  )