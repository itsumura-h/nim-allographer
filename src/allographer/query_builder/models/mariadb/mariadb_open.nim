import std/asyncdispatch
import std/deques
import std/tables
import std/times
import ../../libs/database_url
import ../../libs/mariadb/mariadb_rdb
import ../../error
import ../../log
import ./mariadb_types


proc dbOpen*(_: type MariaDB, database: string, user: string, password: string,
                  host: string, port: int, maxConnections=1, timeout=30,
                  shouldDisplayLog=false, shouldOutputLogFile=false, logDir="",
                  maxConnectionLifetime=DEFAULT_CONN_MAX_LIFETIME_SECONDS,
                  maxConnectionIdleTime=DEFAULT_CONN_MAX_IDLE_SECONDS): MariadbConnections =
  var conns = newSeq[Connection](maxConnections)
  for i in 0..<maxConnections:
    let conn = mariadb_rdb.init(nil)
    if conn == nil:
      mariadb_rdb.close(conn)
      dbError("mariadb_rdb.init() failed")
    if mariadb_rdb.options(conn, MYSQL_OPT_NONBLOCK, nil) != 0:
      let errmsg = $mariadb_rdb.error(conn)
      mariadb_rdb.close(conn)
      dbError(errmsg)
    if mariadb_rdb.real_connect(conn, host, user, password, database, port.int32, nil, 0) == nil:
      var errmsg = $mariadb_rdb.error(conn)
      mariadb_rdb.close(conn)
      dbError(errmsg)
    conns[i] = Connection(
      conn: conn,
      isBusy: false,
      createdAt: getTime().toUnix(),
      lastUsedAt: getTime().toUnix()
    )
  let pools = Connections(
    conns: conns,
    timeout: timeout,
    maxConnectionLifetime: maxConnectionLifetime,
    maxConnectionIdleTime: maxConnectionIdleTime,
    info: ConnectionInfo(
      database: database,
      user: user,
      password: password,
      host: host,
      port: port
    ),
    waiters: initDeque[Future[void]](),
    columnTypeCache: initTable[string, seq[seq[string]]](),
    preparedCache: initTable[string, MariadbPreparedEntry](),
  )
  result = MariadbConnections(
    pools: pools,
    info: pools.info,
    log: LogSetting(shouldDisplayLog:shouldDisplayLog, shouldOutputLogFile:shouldOutputLogFile, logDir:logDir)
  )


proc dbOpen*(_:type MariaDB, url: string, maxConnections: int = 1, timeout=30,
              shouldDisplayLog=false, shouldOutputLogFile=false, logDir="",
              maxConnectionLifetime=DEFAULT_CONN_MAX_LIFETIME_SECONDS,
              maxConnectionIdleTime=DEFAULT_CONN_MAX_IDLE_SECONDS): MariadbConnections =
  return dbOpen(MariaDB, asDatabaseUrl(url), maxConnections, timeout, shouldDisplayLog, shouldOutputLogFile, logDir, maxConnectionLifetime, maxConnectionIdleTime)


proc dbOpen*(_:type MariaDB, databaseUrl: DatabaseUrl, maxConnections=1, timeout=30,
             shouldDisplayLog=false, shouldOutputLogFile=false, logDir="",
             maxConnectionLifetime=DEFAULT_CONN_MAX_LIFETIME_SECONDS,
             maxConnectionIdleTime=DEFAULT_CONN_MAX_IDLE_SECONDS): MariadbConnections =
  let parsed = parseDatabaseUrl(databaseUrl)
  requireDatabaseUrlScheme(parsed, ["mariadb"], "MariaDB")

  let database = databaseName(parsed)
  let port = portOrDefault(parsed, 3306)
  return dbOpen(
    MariaDB,
    database,
    parsed.username,
    parsed.password,
    parsed.hostname,
    port,
    maxConnections,
    timeout,
    shouldDisplayLog,
    shouldOutputLogFile,
    logDir,
    maxConnectionLifetime,
    maxConnectionIdleTime
  )
