import std/times
import std/strutils
import ../../libs/mariadb/mariadb_rdb
import ../../error
import ../../log
import ./mariadb_types


proc dbOpen*(_: type MariaDB, database: string, user: string, password: string,
                  host: string, port: int, maxConnections=1, timeout=30,
                  shouldDisplayLog=false, shouldOutputLogFile=false, logDir=""): MariadbConnections =
  var conns = newSeq[Connection](maxConnections)
  for i in 0..<maxConnections:
    let conn = mariadb_rdb.init(nil)
    if conn == nil:
      mariadb_rdb.close(conn)
      dbError("mariadb_rdb.init() failed")
    if mariadb_rdb.real_connect(conn, host, user, password, database, port.int32, nil, 0) == nil:
      var errmsg = $mariadb_rdb.error(conn)
      mariadb_rdb.close(conn)
      dbError(errmsg)
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
  result = MariadbConnections(
    pools: pools,
    info: info,
    log: LogSetting(shouldDisplayLog:shouldDisplayLog, shouldOutputLogFile:shouldOutputLogFile, logDir:logDir)
  )


proc dbOpen*(_:type MariaDB, url: string, maxConnections=1, timeout=30,
              shouldDisplayLog=false, shouldOutputLogFile=false, logDir=""): MariadbConnections =
  ## url: "mariadb://username:password@localhost:3306/DB_Name"
  let isMariadb = url.startsWith("mariadb://")
  if not isMariadb:
    raise newException(ValueError, "Invalid URL format. Expected a MariaDB URL starting with 'mariadb://'.")

  let user = url.split("://")[1].split(":")[0]
  let password = url.split(":")[2].split("@")[0]
  let host = url.split("@")[1].split(":")[0]
  let port = url.split(":")[3].split("/")[0]
  let database = url.split("/")[^1]

  return dbOpen(Mariadb, database, user, password, host, port.parseInt, maxConnections, timeout, shouldDisplayLog, shouldOutputLogFile, logDir)
