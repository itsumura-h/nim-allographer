import std/asyncdispatch
import std/deques
import std/strutils
import std/tables
import std/times
import ../../libs/database_url
import ../../libs/sqlite/sqlite_rdb
import ../../log
import ./sqlite_types


proc openSqlite(database: string; maxConnections: int; timeout: int;
                shouldDisplayLog: bool; shouldOutputLogFile: bool; logDir: string;
                maxConnectionLifetime: int = DEFAULT_CONN_MAX_LIFETIME_SECONDS;
                maxConnectionIdleTime: int = DEFAULT_CONN_MAX_IDLE_SECONDS): SqliteConnections =
  var conns = newSeq[Connection](maxConnections)
  for i in 0..<maxConnections:
    var db: PSqlite3
    discard sqlite_rdb.open(database, db)
    conns[i] = Connection(
      conn: db,
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
    waiters: initDeque[Future[void]](),
    columnTypeCache: initTable[string, seq[(string, string)]](),
    preparedCache: initTable[string, SqlitePreparedEntry](),
  )
  result = SqliteConnections(
    pools: pools,
    log: LogSetting(shouldDisplayLog:shouldDisplayLog, shouldOutputLogFile:shouldOutputLogFile, logDir:logDir)
  )


proc dbOpen*(_:type SQLite3, database: string = "",
              maxConnections: int = 1, timeout=30,
              shouldDisplayLog=false, shouldOutputLogFile=false, logDir="",
              maxConnectionLifetime=DEFAULT_CONN_MAX_LIFETIME_SECONDS,
              maxConnectionIdleTime=DEFAULT_CONN_MAX_IDLE_SECONDS): SqliteConnections =
  if database.len > 0 and database.contains("://"):
    let parsed = parseDatabaseUrl(asDatabaseUrl(database))
    requireDatabaseUrlScheme(parsed, ["sqlite"], "SQLite")
    return openSqlite(sqliteDatabasePath(parsed), maxConnections, timeout, shouldDisplayLog, shouldOutputLogFile, logDir, maxConnectionLifetime, maxConnectionIdleTime)

  return openSqlite(database, maxConnections, timeout, shouldDisplayLog, shouldOutputLogFile, logDir, maxConnectionLifetime, maxConnectionIdleTime)


proc dbOpen*(_:type SQLite3, databaseUrl: DatabaseUrl,
             maxConnections: int = 1, timeout=30,
             shouldDisplayLog=false, shouldOutputLogFile=false, logDir="",
             maxConnectionLifetime=DEFAULT_CONN_MAX_LIFETIME_SECONDS,
             maxConnectionIdleTime=DEFAULT_CONN_MAX_IDLE_SECONDS): SqliteConnections =
  let parsed = parseDatabaseUrl(databaseUrl)
  requireDatabaseUrlScheme(parsed, ["sqlite"], "SQLite")
  let database = sqliteDatabasePath(parsed)
  return openSqlite(database, maxConnections, timeout, shouldDisplayLog, shouldOutputLogFile, logDir, maxConnectionLifetime, maxConnectionIdleTime)
