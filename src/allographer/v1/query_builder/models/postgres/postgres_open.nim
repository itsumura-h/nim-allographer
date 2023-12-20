import std/times
import ../../libs/postgres/postgres_rdb
import ../../libs/postgres/postgres_lib
import ../../log
import ./postgres_types


proc dbOpen*(_:type PostgreSQL, database: string = "", user: string = "", password: string = "",
                    host: string = "", port: int = 0, maxConnections: int = 1, timeout=30,
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
