import std/tables
import std/times
import ../../libs/database_url
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
    timeout: timeout,
    preparedCache: initTable[string, MysqlPreparedEntry](),
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
  return dbOpen(MySQL, asDatabaseUrl(url), maxConnections, timeout, shouldDisplayLog, shouldOutputLogFile, logDir)


proc dbOpen*(_:type MySQL, databaseUrl: DatabaseUrl, maxConnections=1, timeout=30,
             shouldDisplayLog=false, shouldOutputLogFile=false, logDir=""): MysqlConnections =
  let parsed = parseDatabaseUrl(databaseUrl)
  requireDatabaseUrlScheme(parsed, ["mysql"], "MySQL")

  let database = databaseName(parsed)
  let port = portOrDefault(parsed, 3306)
  return dbOpen(
    MySQL,
    database,
    parsed.username,
    parsed.password,
    parsed.hostname,
    port,
    maxConnections,
    timeout,
    shouldDisplayLog,
    shouldOutputLogFile,
    logDir
  )
