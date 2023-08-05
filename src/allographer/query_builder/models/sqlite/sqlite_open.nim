import std/times
import ../../libs/sqlite/sqlite_rdb
import ./sqlite_types


proc sqliteOpen*(database: string = "", user: string = "", password: string = "", host: string = "", port: int32 = 0, maxConnections: int = 1, timeout=30): SqliteConnections =
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
    timeout: timeout
  )
