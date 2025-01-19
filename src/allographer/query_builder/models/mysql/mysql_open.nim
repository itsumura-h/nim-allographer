import std/times
import std/strutils
import ../../libs/mysql/mysql_rdb
import ../../error
import ../../log
import ./mysql_types


proc dbOpen*(_:type MySQL, database: string, user: string, password: string,
              host: string, port: int, maxConnections: int = 1, timeout=30,
              shouldDisplayLog=false, shouldOutputLogFile=false, logDir=""): MysqlConnections =
  var conns = newSeq[Connection](maxConnections)
  for i in 0..<maxConnections:
    let conn = mysql_rdb.init(nil)
    if conn == nil:
      mysql_rdb.close(conn)
      dbError("mysql_rdb.init() failed")
    if mysql_rdb.real_connect(conn, host, user, password, database, port.int32, nil, 0) == nil:
      var errmsg = $mysql_rdb.error(conn)
      mysql_rdb.close(conn)
      let info = {
        "database": database,
        "user": user,
        "password": password,
        "host": host,
        "port": $port
      }
      dbError(errmsg & $info)
    conns[i] = Connection(
      conn: conn,
      isBusy: false,
      createdAt: getTime().toUnix()
    )
  let pools = Connections(
    conns: conns,
    timeout: timeout
  )
  let info = ConnectionInfo(
    database:database,
    user:user,
    password:password,
    host:host,
    port:port
  )
  result = MysqlConnections(
    pools: pools,
    info: info,
    log: LogSetting(shouldDisplayLog:shouldDisplayLog, shouldOutputLogFile:shouldOutputLogFile, logDir:logDir)
  )


proc dbOpen*(_:type MySQL, url: string, maxConnections=1, timeout=30,
              shouldDisplayLog=false, shouldOutputLogFile=false, logDir=""): MysqlConnections =
  ## url: "mysql://username:password@localhost:3306/DB_Name"
  let isMariadb = url.startsWith("mysql://")
  if not isMariadb:
    raise newException(ValueError, "Invalid URL format. Expected a MariaDB URL starting with 'mariadb://'.")

  let user = url.split("://")[1].split(":")[0]
  let password = url.split(":")[2].split("@")[0]
  let host = url.split("@")[1].split(":")[0]
  let port = url.split(":")[3].split("/")[0]
  let database = url.split("/")[^1]

  return dbOpen(MySQL, database, user, password, host, port.parseInt, maxConnections, timeout, shouldDisplayLog, shouldOutputLogFile, logDir)
