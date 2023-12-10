import std/times
import ../../libs/mariadb/mariadb_rdb
import ../../error
import ../../log
import ./mariadb_types


proc dbOpen*(_: type MariaDB, database: string = "", user: string = "", password: string = "",
                  host: string = "", port: int = 0, maxConnections: int = 1, timeout=30,
                  shouldDisplayLog=false, shouldOutputLogFile=false, logDir=""): MariadbConnections =
  var pools = newSeq[MariadbConnection](maxConnections)
  for i in 0..<maxConnections:
    let conn = mariadb_rdb.init(nil)
    if conn == nil:
      mariadb_rdb.close(conn)
      dbError("mariadb_rdb.init() failed")
    if mariadb_rdb.real_connect(conn, host, user, password, database, port.int32, nil, 0) == nil:
      var errmsg = $mariadb_rdb.error(conn)
      mariadb_rdb.close(conn)
      dbError(errmsg)
    pools[i] = MariadbConnection(
      conn: conn,
      isBusy: false,
      createdAt: getTime().toUnix()
    )
  let info = MariadbConnectionInfo(
    database:database,
    user:user,
    password:password,
    host:host,
    port:port
  )
  result = MariadbConnections(
    pools: pools,
    timeout: timeout,
    info: info,
    log: LogSetting(shouldDisplayLog:shouldDisplayLog, shouldOutputLogFile:shouldOutputLogFile, logDir:logDir)
  )
