import std/asyncdispatch
import std/deques
import std/tables
import std/times
import ../database_types
import ../../error
import ../../libs/database_url
import ../../libs/postgres/postgres_rdb
import ../../libs/postgres/postgres_lib
import ../../log
import ./postgres_types

proc dbOpen*(_:type PostgreSQL, database: string, user: string, password: string,
              host: string, port: int, maxConnections=1, timeout=30,
              shouldDisplayLog=false, shouldOutputLogFile=false, logDir="",
              maxConnectionLifetime=DEFAULT_CONN_MAX_LIFETIME_SECONDS,
              maxConnectionIdleTime=DEFAULT_CONN_MAX_IDLE_SECONDS): PostgresConnections =
  var conns = newSeq[Connection](maxConnections)
  for i in 0..<maxConnections:
    let conn = postgres_rdb.pqsetdbLogin(host, port.`$`.cstring, nil, nil, database, user, password)
    if pqStatus(conn) != CONNECTION_OK: dbError(conn)
    if pqsetnonblocking(conn, 1'i32) != 0'i32:
      dbError(conn)
    if pqisnonblocking(conn) != 1'i32:
      raise newException(DbError, "PostgreSQL connection could not be set to non-blocking mode")
    conns[i] = Connection(
      conn: conn,
      isBusy: false,
      createdAt: getTime().toUnix(),
      lastUsedAt: getTime().toUnix(),
    )
  let pools = Connections(
    conns: conns,
    timeout: timeout,
    maxConnectionLifetime: maxConnectionLifetime,
    maxConnectionIdleTime: maxConnectionIdleTime,
    database: database,
    user: user,
    password: password,
    host: host,
    port: port,
    waiters: initDeque[Future[void]](),
    columnTypeCache: initTable[string, seq[Row]](),
    preparedCache: initTable[string, PostgresPreparedEntry](),
  )
  result = PostgresConnections(
    pools: pools,
    log: LogSetting(shouldDisplayLog:shouldDisplayLog, shouldOutputLogFile:shouldOutputLogFile, logDir:logDir)
  )


proc dbOpen*(_:type PostgreSQL, url: string, maxConnections: int = 1, timeout=30,
              shouldDisplayLog=false, shouldOutputLogFile=false, logDir="",
              maxConnectionLifetime=DEFAULT_CONN_MAX_LIFETIME_SECONDS,
              maxConnectionIdleTime=DEFAULT_CONN_MAX_IDLE_SECONDS): PostgresConnections =
  return dbOpen(PostgreSQL, asDatabaseUrl(url), maxConnections, timeout, shouldDisplayLog, shouldOutputLogFile, logDir, maxConnectionLifetime, maxConnectionIdleTime)


proc dbOpen*(_:type PostgreSQL, databaseUrl: DatabaseUrl, maxConnections: int = 1, timeout=30,
             shouldDisplayLog=false, shouldOutputLogFile=false, logDir="",
             maxConnectionLifetime=DEFAULT_CONN_MAX_LIFETIME_SECONDS,
             maxConnectionIdleTime=DEFAULT_CONN_MAX_IDLE_SECONDS): PostgresConnections =
  let parsed = parseDatabaseUrl(databaseUrl)
  requireDatabaseUrlScheme(parsed, ["postgresql", "postgres"], "PostgreSQL")

  let database = databaseName(parsed)
  let port = portOrDefault(parsed, 5432)
  return dbOpen(
    PostgreSQL,
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
