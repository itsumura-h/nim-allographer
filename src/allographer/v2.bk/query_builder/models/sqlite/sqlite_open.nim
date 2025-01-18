import std/times
import ../../libs/sqlite/sqlite_rdb
import ../../log
import ./sqlite_types


proc dbOpen*(_:type SQLite3, database: string = "", 
              maxConnections: int = 1, timeout=30,
              shouldDisplayLog=false, shouldOutputLogFile=false, logDir=""): SqliteConnections =
  var conns = newSeq[Connection](maxConnections)
  for i in 0..<maxConnections:
    var db: PSqlite3
    discard sqlite_rdb.open(database, db)
    conns[i] = Connection(
      conn: db,
      isBusy: false,
      createdAt: getTime().toUnix(),
    )
  let pools = Connections(
    conns:conns,
    timeout:timeout
  )
  result = SqliteConnections(
    pools: pools,
    log: LogSetting(shouldDisplayLog:shouldDisplayLog, shouldOutputLogFile:shouldOutputLogFile, logDir:logDir)
  )
