import std/times
import ../../../env
import ../../libs/postgres/postgres_rdb
import ../../libs/postgres/postgres_lib
import ./postgres_types


proc postgresOpen*(database: string = "", user: string = "", password: string = "", host: string = "", port: int32 = 0, maxConnections: int = 1, timeout=30): PostgresConnections =
  when isExistsPostgres:
    var pools = newSeq[PostgresConnection](maxConnections)
    for i in 0..<maxConnections:
      let conn = postgres_rdb.pqsetdbLogin(host, port.`$`.cstring, nil, nil, database, user, password)
      if pqStatus(conn) != CONNECTION_OK: dbError(conn)
      pools[i] = PostgresConnection(
        conn: conn,
        isBusy: false,
        createdAt: getTime().toUnix(),
      )
    result = PostgresConnections(
      pools: pools,
      timeout: timeout
    )
