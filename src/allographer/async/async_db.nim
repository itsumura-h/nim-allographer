import asyncdispatch, macros, strutils, strformat
import database/base
import ../base as a
import database/impls/mysql, database/impls/mariadb, database/impls/postgres, database/impls/sqlite
import ../baseEnv

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

proc query*(self: Connections, driver:Driver, query: string, args: seq[string] = @[]):Future[(seq[Row], DbRows)] {.async.} =
  await sleepAsync(0)
  let connI = await getFreeConn(self)
  defer: self.returnConn(connI)
  if connI == errorConnectionNum:
    return
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

proc queryPlain*(self: Connections, driver:Driver, query: string, args: seq[string] = @[]):Future[seq[Row]] {.async.} =
  let connI = await getFreeConn(self)
  defer: self.returnConn(connI)
  if connI == errorConnectionNum:
    return
  await sleepAsync(0)
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


proc exec*(self: Connections, driver:Driver, query: string, args: seq[string] = @[]) {.async.} =
  let connI = await getFreeConn(self)
  defer: self.returnConn(connI)
  if connI == errorConnectionNum:
    return
  await sleepAsync(0)
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
  self.returnConn(connI)

proc getColumns*(self:Connections, driver:Driver, query:string, args: seq[string] = @[]):Future[seq[string]] {.async.} =
  await sleepAsync(0)
  let connI = await getFreeConn(self)
  defer: self.returnConn(connI)
  if connI == errorConnectionNum:
    return
  case driver
  of MySQL:
    when isExistsMysql:
      discard
      # return await mysql.query(self.pools[connI].mysqlConn, query, args, self.timeout)
  of MariaDB:
    when isExistsMariadb:
      discard
      # return await mariadb.query(self.pools[connI].mariadbConn, query, args, self.timeout)
  of PostgreSQL:
    when isExistsPostgres:
      discard
      # return await postgres.query(self.pools[connI].postgresConn, query, args, self.timeout)
  of SQLite3:
    when isExistsSqlite:
      return await sqlite.getColumns(self.pools[connI].sqliteConn, query, args, self.timeout)

proc prepare*(self: Connections, driver:Driver, query: string, stmtName=""):Future[Prepared] {.async.} =
  let stmtName =
    if stmtName.len == 0:
      randStr(10)
    else:
      stmtName
  let connI = await getFreeConn(self)
  if connI == errorConnectionNum:
    return
  await sleepAsync(0)
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
      let nArgs = await postgres.prepare(self.pools[connI].postgresConn, query, self.timeout, stmtName)
      result = Prepared(conn:self, nArgs:nArgs, pgStmt:stmtName, connI:connI)
  of SQLite3:
    when isExistsSqlite:
      let sqliteStmt = await sqlite.prepare(self.pools[connI].sqliteConn, query, self.timeout)
      result = Prepared(conn:self, sqliteStmt:sqliteStmt, connI:connI)

proc query*(self:Prepared, driver:Driver, args: seq[string] = @[]):Future[(seq[Row], DbRows)] {.async.} =
  await sleepAsync(0)
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
  await sleepAsync(0)
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

proc close*(self:Prepared) =
  self.conn.returnConn(self.connI)
