import std/strutils
import ../src/allographer/connection

let
  maxConnections = 95
  timeout = 30
  mysqlUrl = "mysql://user:pass@mysql:3306/database"
  mariadbUrl = "mariadb://user:pass@mariadb:3306/database"
  pgUrl = "postgresql://user:pass@postgres:5432/database"

  # rdb* = dbOpen(SQLite3, sqliteHost, maxConnections=maxConnections, shouldDisplayLog=false)
  rdb* = dbOpen(SQLite3, ":memory:", maxConnections=maxConnections, shouldDisplayLog=false)
  # rdb* = dbOpen(MySQL, mysqlUrl, maxConnections, timeout, shouldDisplayLog=true)
  # rdb* = dbOpen(MariaDB, mariadbUrl, maxConnections, timeout, shouldDisplayLog=true)
  # rdb* = dbOpen(PostgreSQL, pgUrl, maxConnections, timeout, shouldDisplayLog=true)

template asyncBlock*(body:untyped) =
  (proc(){.async.}=
    body
  )()
  .waitFor()
