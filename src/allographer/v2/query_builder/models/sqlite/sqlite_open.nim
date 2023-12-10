import std/times
import ../../libs/sqlite/sqlite_rdb
import ../../log
import ./sqlite_types


proc dbOpen*(_:type SQLite3, database: string = "", 
              maxConnections: int = 1, timeout=30,
              shouldDisplayLog=false, shouldOutputLogFile=false, logDir=""): SqliteConnections =
  var pools = newSeq[SqliteConnection](maxConnections)
  for i in 0..<maxConnections:
    var db: PSqlite3
    discard sqlite_rdb.open(database, db)
    pools[i] = SqliteConnection(
      conn: db,
      isBusy: false,
      createdAt: getTime().toUnix(),
    )
  result = SqliteConnections(
    pools: pools,
    timeout: timeout,
    log: LogSetting(shouldDisplayLog:shouldDisplayLog, shouldOutputLogFile:shouldOutputLogFile, logDir:logDir)
  )
