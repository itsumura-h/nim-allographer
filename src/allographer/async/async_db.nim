import
  std/asyncdispatch,
  std/strutils,
  ../baseEnv,
  ../base as a,
  ./database/base,
  ./database/impls/mysql,
  ./database/impls/mariadb,
  ./database/impls/postgres,
  ./database/impls/sqlite

export base


proc open*(driver:Driver, database:string="", user:string="", password:string="",
            host: string="", port=0, maxConnections=1, timeout=30): Connections =
  case driver:
  of MySQL:
    when isExistsMysql:
      result = mysql.dbopen(database, user, password, host, port.int32, maxConnections, timeout)
  of MariaDB:
    when isExistsMariadb:
      result = mariadb.dbopen(database, user, password, host, port.int32, maxConnections, timeout)
  of PostgreSQL:
    when isExistsPostgres:
      result = postgres.dbopen(database, user, password, host, port.int32, maxConnections, timeout)
  of SQLite3:
    when isExistsSqlite:
      result = sqlite.dbopen(database, user, password, host, port.int32, maxConnections, timeout)


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
    defer: self.returnConn(connI).await
    connI = getFreeConn(self).await
  if connI == errorConnectionNum:
    return
  sleepAsync(0).await
  case driver
  of MySQL:
    when isExistsMysql:
      return await mysql.query(self.pools[connI].mysqlConn, query, args, self.timeout)
  of MariaDB:
    when isExistsMariadb:
      return await mariadb.query(self.pools[connI].mariadbConn, query, args, self.timeout)
  of PostgreSQL:
    when isExistsPostgres:
      discard
      return await postgres.query(self.pools[connI].postgresConn, query, args, self.timeout)
  of SQLite3:
    when isExistsSqlite:
      return await sqlite.query(self.pools[connI].sqliteConn, query, args, self.timeout)


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
    defer: self.returnConn(connI).await
    connI = getFreeConn(self).await
  if connI == errorConnectionNum:
    return
  sleepAsync(0).await
  case driver
  of MySQL:
    when isExistsMysql:
      discard
      return await mysql.queryPlain(self.pools[connI].mysqlConn, query, args, self.timeout)
  of MariaDB:
    when isExistsMariadb:
      return await mariadb.queryPlain(self.pools[connI].mariadbConn, query, args, self.timeout)
  of PostgreSQL:
    when isExistsPostgres:
      discard
      return await postgres.queryPlain(self.pools[connI].postgresConn, query, args, self.timeout)
  of SQLite3:
    when isExistsSqlite:
      discard
      return await sqlite.queryPlain(self.pools[connI].sqliteConn, query, args, self.timeout)


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
    defer: self.returnConn(connI).await
    connI = getFreeConn(self).await
  if connI == errorConnectionNum:
    return
  sleepAsync(0).await
  case driver
  of MySQL:
    when isExistsMysql:
      await mysql.exec(self.pools[connI].mysqlConn, query, args, self.timeout)
  of MariaDB:
    when isExistsMariadb:
      await mariadb.exec(self.pools[connI].mariadbConn, query, args, self.timeout)
  of PostgreSQL:
    when isExistsPostgres:
      await postgres.exec(self.pools[connI].postgresConn, query, args, self.timeout)
  of SQLite3:
    when isExistsSqlite:
      await sqlite.exec(self.pools[connI].sqliteConn, query, args, self.timeout)


proc transactionStart*(self: Connections, driver:Driver):Future[int] {.async.} =
  let connI = getFreeConn(self).await
  if connI == errorConnectionNum:
    return
  sleepAsync(0).await
  case driver
  of MySQL:
    when isExistsMysql:
      await mysql.exec(self.pools[connI].mysqlConn, "BEGIN", @[], self.timeout)
  of MariaDB:
    when isExistsMariadb:
      await mariadb.exec(self.pools[connI].mariadbConn, "BEGIN", @[], self.timeout)
  of PostgreSQL:
    when isExistsPostgres:
      await postgres.exec(self.pools[connI].postgresConn, "BEGIN", @[], self.timeout)
  of SQLite3:
    when isExistsSqlite:
      await sqlite.exec(self.pools[connI].sqliteConn, "BEGIN", @[], self.timeout)
  return connI

proc transactionEnd*(self: Connections, driver:Driver, connI:int, query:string) {.async.} =
  defer: self.returnConn(connI).await
  if connI == errorConnectionNum:
    return
  sleepAsync(0).await
  case driver
  of MySQL:
    when isExistsMysql:
      await mysql.exec(self.pools[connI].mysqlConn, query, @[], self.timeout)
  of MariaDB:
    when isExistsMariadb:
      await mariadb.exec(self.pools[connI].mariadbConn, query, @[], self.timeout)
  of PostgreSQL:
    when isExistsPostgres:
      await postgres.exec(self.pools[connI].postgresConn, query, @[], self.timeout)
  of SQLite3:
    when isExistsSqlite:
      await sqlite.exec(self.pools[connI].sqliteConn, query, @[], self.timeout)


proc getColumns*(self:Connections, driver:Driver, query:string, args: seq[string] = @[]):Future[seq[string]] {.async.} =
  let connI = getFreeConn(self).await
  defer: self.returnConn(connI).await
  if connI == errorConnectionNum:
    return
  sleepAsync(0).await
  case driver
  of MySQL:
    when isExistsMysql:
      discard
      # return await mysql.getColumns(self.pools[connI].mysqlConn, query, args, self.timeout)
  of MariaDB:
    when isExistsMariadb:
      discard
      # return await mariadb.getColumns(self.pools[connI].mariadbConn, query, args, self.timeout)
  of PostgreSQL:
    when isExistsPostgres:
      discard
      # return await postgres.getColumns(self.pools[connI].postgresConn, query, args, self.timeout)
  of SQLite3:
    when isExistsSqlite:
      return await sqlite.getColumns(self.pools[connI].sqliteConn, query, args, self.timeout)


proc prepare*(self: Connections, driver:Driver, query: string, stmtName=""):Future[Prepared] {.async.} =
  let connI = getFreeConn(self).await
  if connI == errorConnectionNum:
    return
  sleepAsync(0).await
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
    when isExistsPostgres:
      let stmtName =
        if stmtName.len == 0:
          randStr(10)
        else:
          stmtName
      let nArgs = await postgres.prepare(self.pools[connI].postgresConn, query, self.timeout, stmtName)
      result = Prepared(conn:self, nArgs:nArgs, pgStmt:stmtName, connI:connI)
  of SQLite3:
    when isExistsSqlite:
      let sqliteStmt = await sqlite.prepare(self.pools[connI].sqliteConn, query, self.timeout)
      result = Prepared(conn:self, sqliteStmt:sqliteStmt, connI:connI)


proc query*(self:Prepared, driver:Driver, args: seq[string] = @[]):Future[(seq[Row], DbRows)] {.async.} =
  sleepAsync(0).await
  case driver
  of MySQL:
    when isExistsMysql:
      discard
  of MariaDB:
    when isExistsMariadb:
      discard
  of PostgreSQL:
    when isExistsPostgres:
      return await postgres.preparedQuery(self.conn.pools[self.connI].postgresConn, args, self.nArgs, self.conn.timeout, self.pgStmt)
  of SQLite3:
    when isExistsSqlite:
      return await sqlite.preparedQuery(self.conn.pools[self.connI].sqliteConn, args, self.sqliteStmt)


proc exec*(self:Prepared, driver:Driver, args:seq[string] = @[]) {.async.} =
  sleepAsync(0).await
  case driver
  of MySQL:
    when isExistsMysql:
      discard
  of MariaDB:
    when isExistsMariadb:
      discard
  of PostgreSQL:
    when isExistsPostgres:
      await postgres.preparedExec(self.conn.pools[self.connI].postgresConn, args, self.nArgs, self.conn.timeout, self.pgStmt)
  of SQLite3:
    when isExistsSqlite:
      await sqlite.preparedExec(self.conn.pools[self.connI].sqliteConn, args, self.sqliteStmt)


proc close*(self:Prepared) {.async.}=
  self.conn.returnConn(self.connI).await
