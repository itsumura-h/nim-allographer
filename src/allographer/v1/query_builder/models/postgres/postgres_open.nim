import std/times
import ../../libs/postgres/postgres_rdb
import ../../libs/postgres/postgres_lib
import ../../log
import ./postgres_types


proc dbOpen*(_:type PostgreSQL, database: string, user: string, password: string,
              host: string, port: int, maxConnections=1, timeout=30,
              shouldDisplayLog=false, shouldOutputLogFile=false, logDir=""): PostgresConnections =
  var conns = newSeq[Connection](maxConnections)
  for i in 0..<maxConnections:
    let conn = postgres_rdb.pqsetdbLogin(host, port.`$`.cstring, nil, nil, database, user, password)
    if pqStatus(conn) != CONNECTION_OK: dbError(conn)
    conns[i] = Connection(
      conn: conn,
      isBusy: false,
      createdAt: getTime().toUnix(),
    )
  let pools = Connections(
    conns:conns,
    timeout:timeout
  )
  result = PostgresConnections(
    pools: pools,
    log: LogSetting(shouldDisplayLog:shouldDisplayLog, shouldOutputLogFile:shouldOutputLogFile, logDir:logDir)
  )


proc dbOpen*(_:type PostgreSQL, url: string, maxConnections: int = 1, timeout=30,
              shouldDisplayLog=false, shouldOutputLogFile=false, logDir=""): PostgresConnections =
  ## url: "postgresql://user:pass@host:port/database"
  let isPostgres = url.startsWith("postgresql://")
  if not isPostgres:
    raise newException(ValueError, "Invalid URL format. Expected a PostgreSQL URL starting with 'postgresql://'.")
  
  let user = url.split("://")[1].split(":")[0]
  let password = url.split(":")[2].split("@")[0]
  let host = url.split("@")[1].split(":")[0]
  let port = url.split(":")[3].split("/")[0]
  let database = url.split("/")[^1]

  return dbOpen(PostgreSQL, database, user, password, host, port.parseInt, maxConnections, timeout, shouldDisplayLog, shouldOutputLogFile, logDir)
