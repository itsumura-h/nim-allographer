import std/asyncdispatch
import std/strutils
import ../../../env
import ../rdb_types
import ../databases/database_types; export database_types
import ../databases/sqlite/sqlite_impl
import ../databases/postgres/postgres_impl
# import ../databases/mysql/mysql_impl
import ../databases/mariadb/mariadb_impl


proc open*(driver:Driver, database:string="", user:string="", password:string="",
            host: string="", port=0, maxConnections=1, timeout=30): Connections =
  case driver
  of SQLite3:
    when isExistsSqlite:
      result = sqlite_impl.dbopen(database, user, password, host, port.int32, maxConnections, timeout)
  of PostgreSQL:
    when isExistsPostgre:
      result = postgres_impl.dbopen(database, user, password, host, port.int32, maxConnections, timeout)
  of MySQL:
    when isExistsMysql:
      result = mariadb_impl.dbopen(database, user, password, host, port.int32, maxConnections, timeout)
      # result = mysql.dbopen(database, user, password, host, port.int32, maxConnections, timeout)
  of MariaDB:
    when isExistsMariadb:
      result = mariadb_impl.dbopen(database, user, password, host, port.int32, maxConnections, timeout)


proc query*(
  self: Connections,
  driver:Driver,
  query: string,
  args: seq[string] = @[],
  specifiedConnI=false,
  connI=0
):Future[(seq[Row], DbRows)] {.async.} =
  var connI = connI
  if not specifiedConnI:
    connI = getFreeConn(self).await
  defer:
    if not specifiedConnI:
      self.returnConn(connI).await
  if connI == errorConnectionNum:
    return
  case driver
  of SQLite3:
    when isExistsSqlite:
      return await sqlite_impl.query(self.pools[connI].sqliteConn, query, args, self.timeout)
  of PostgreSQL:
    when isExistsPostgre:
      return await postgres_impl.query(self.pools[connI].postgresConn, query, args, self.timeout)
  of MySQL:
    when isExistsMysql:
      return await mariadb_impl.query(self.pools[connI].mariadbConn, query, args, self.timeout)
      # return await mysql.query(self.pools[connI].mysqlConn, query, args, self.timeout)
  of MariaDB:
    when isExistsMariadb:
      return await mariadb_impl.query(self.pools[connI].mariadbConn, query, args, self.timeout)


proc queryPlain*(
  self: Connections,
  driver:Driver,
  query: string,
  args: seq[string] = @[],
  specifiedConnI=false,
  connI=0
):Future[seq[Row]] {.async.} =
  var connI = connI
  if not specifiedConnI:
    connI = getFreeConn(self).await
  defer:
    if not specifiedConnI:
      self.returnConn(connI).await
  if connI == errorConnectionNum:
    return
  case driver
  of SQLite3:
    when isExistsSqlite:
      return await sqlite_impl.queryPlain(self.pools[connI].sqliteConn, query, args, self.timeout)
  of PostgreSQL:
    when isExistsPostgre:
      return await postgres_impl.queryPlain(self.pools[connI].postgresConn, query, args, self.timeout)
  of MySQL:
    when isExistsMysql:
      return await mariadb_impl.queryPlain(self.pools[connI].mariadbConn, query, args, self.timeout)
      # return await mysql.queryPlain(self.pools[connI].mysqlConn, query, args, self.timeout)
  of MariaDB:
    when isExistsMariadb:
      return await mariadb_impl.queryPlain(self.pools[connI].mariadbConn, query, args, self.timeout)


proc exec*(
  self: Connections,
  driver:Driver,
  query: string,
  args: seq[string] = @[],
  specifiedConnI=false,
  connI=0
) {.async.} =
  var connI = connI
  if not specifiedConnI:
    connI = getFreeConn(self).await
  defer:
    if not specifiedConnI:
      self.returnConn(connI).await
  if connI == errorConnectionNum:
    return
  case driver
  of SQLite3:
    when isExistsSqlite:
      await sqlite_impl.exec(self.pools[connI].sqliteConn, query, args, self.timeout)
  of PostgreSQL:
    when isExistsPostgre:
      await postgres_impl.exec(self.pools[connI].postgresConn, query, args, self.timeout)
  of MySQL:
    when isExistsMysql:
      await mariadb_impl.exec(self.pools[connI].mariadbConn, query, args, self.timeout)
      # await mysql.exec(self.pools[connI].mysqlConn, query, args, self.timeout)
  of MariaDB:
    when isExistsMariadb:
      await mariadb_impl.exec(self.pools[connI].mariadbConn, query, args, self.timeout)


proc transactionStart*(self: Connections, driver:Driver):Future[int] {.async.} =
  let connI = getFreeConn(self).await
  if connI == errorConnectionNum:
    return
  case driver
  of MySQL:
    when isExistsMysql:
      await mariadb_impl.exec(self.pools[connI].mariadbConn, "BEGIN", @[], self.timeout)
      # await mysql.exec(self.pools[connI].mysqlConn, "BEGIN", @[], self.timeout)
  of MariaDB:
    when isExistsMariadb:
      await mariadb_impl.exec(self.pools[connI].mariadbConn, "BEGIN", @[], self.timeout)
  of PostgreSQL:
    when isExistsPostgre:
      await postgres_impl.exec(self.pools[connI].postgresConn, "BEGIN", @[], self.timeout)
  of SQLite3:
    when isExistsSqlite:
      await sqlite_impl.exec(self.pools[connI].sqliteConn, "BEGIN", @[], self.timeout)

  return connI


proc transactionEnd*(self: Connections, driver:Driver, connI:int, query:string) {.async.} =
  defer: self.returnConn(connI).await
  if connI == errorConnectionNum:
    return
  case driver
  of MySQL:
    when isExistsMysql:
      await mariadb_impl.exec(self.pools[connI].mariadbConn, query, @[], self.timeout)
      # await mysql.exec(self.pools[connI].mysqlConn, query, @[], self.timeout)
  of MariaDB:
    when isExistsMariadb:
      await mariadb_impl.exec(self.pools[connI].mariadbConn, query, @[], self.timeout)
  of PostgreSQL:
    when isExistsPostgre:
      await postgres_impl.exec(self.pools[connI].postgresConn, query, @[], self.timeout)
  of SQLite3:
    when isExistsSqlite:
      await sqlite_impl.exec(self.pools[connI].sqliteConn, query, @[], self.timeout)


proc getColumns*(self:Connections, driver:Driver, query:string, args: seq[string] = @[]):Future[seq[string]] {.async.} =
  let connI = getFreeConn(self).await
  defer: self.returnConn(connI).await
  if connI == errorConnectionNum:
    return
  case driver
  of MySQL:
    when isExistsMysql:
      discard
      # return await mysql_impl.getColumns(self.pools[connI].mysqlConn, query, args, self.timeout)
  of MariaDB:
    when isExistsMariadb:
      discard
      return await mariadb_impl.getColumns(self.pools[connI].mariadbConn, query, args, self.timeout)
  of PostgreSQL:
    when isExistsPostgre:
      return await postgres_impl.getColumns(self.pools[connI].postgresConn, query, args, self.timeout)
  of SQLite3:
    when isExistsSqlite:
      return await sqlite_impl.getColumns(self.pools[connI].sqliteConn, query, args, self.timeout)


proc prepare*(self: Connections, driver:Driver, query: string, stmtName=""):Future[Prepared] {.async.} =
  let connI = getFreeConn(self).await
  if connI == errorConnectionNum:
    return
  case driver
  of MySQL:
    when isExistsMysql:
      discard
      # await mysql.prepare(self.pools[connI].mysqlConn, query, self.timeout)
  of MariaDB:
    when isExistsMariadb:
      discard
      # await mariadb.prepare(self.pools[connI].mariadbConn, query, self.timeout)
  of PostgreSQL:
    when isExistsPostgre:
      let stmtName =
        if stmtName.len == 0:
          randStr(10)
        else:
          stmtName
      let nArgs = await postgres_impl.prepare(self.pools[connI].postgresConn, query, self.timeout, stmtName)
      result = Prepared(conn:self, nArgs:nArgs, pgStmt:stmtName, connI:connI)
  of SQLite3:
    when isExistsSqlite:
      let sqliteStmt = await sqlite_impl.prepare(self.pools[connI].sqliteConn, query, self.timeout)
      result = Prepared(conn:self, sqliteStmt:sqliteStmt, connI:connI)


proc query*(self:Prepared, driver:Driver, args: seq[string] = @[]):Future[(seq[Row], DbRows)] {.async.} =
  case driver
  of MySQL:
    when isExistsMysql:
      discard
  of MariaDB:
    when isExistsMariadb:
      discard
  of PostgreSQL:
    when isExistsPostgre:
      return await postgres_impl.preparedQuery(self.conn.pools[self.connI].postgresConn, args, self.nArgs, self.conn.timeout, self.pgStmt)
  of SQLite3:
    when isExistsSqlite:
      return await sqlite_impl.preparedQuery(self.conn.pools[self.connI].sqliteConn, args, self.sqliteStmt)


proc exec*(self:Prepared, driver:Driver, args:seq[string] = @[]) {.async.} =
  case driver
  of MySQL:
    when isExistsMysql:
      discard
  of MariaDB:
    when isExistsMariadb:
      discard
  of PostgreSQL:
    when isExistsPostgre:
      await postgres_impl.preparedExec(self.conn.pools[self.connI].postgresConn, args, self.nArgs, self.conn.timeout, self.pgStmt)
  of SQLite3:
    when isExistsSqlite:
      await sqlite_impl.preparedExec(self.conn.pools[self.connI].sqliteConn, args, self.sqliteStmt)


proc close*(self:Prepared) {.async.}=
  self.conn.returnConn(self.connI).await
