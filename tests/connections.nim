import
  std/os,
  std/strutils,
  ../src/allographer/connection

let
  database = getEnv("DB_DATABASE")
  user = getEnv("DB_USER")
  password = getEnv("DB_PASSWORD")
  sqliteHost = getEnv("SQLITE_HOST")
  mariadbHost = getEnv("MARIA_HOST")
  mysqlPort = getEnv("MY_PORT").parseInt
  pgHost = getEnv("PG_HOST")
  pgPort = getEnv("PG_PORT").parseInt
  maxConnections = getEnv("DB_MAX_CONNECTION").parseInt
  timeout = getEnv("DB_TIMEOUT").parseInt

let rdb* = dbopen(SQLite3, ":memory:", maxConnections=maxConnections, shouldDisplayLog=true)

let dbConnections* = @[
  # dbopen(SQLite3, sqliteHost, maxConnections=95, timeout=timeout, shouldDisplayLog=false),
  dbopen(SQLite3, ":memory:", maxConnections=95, timeout=timeout, shouldDisplayLog=true),
  dbopen(PostgreSQL, database, user, password, pgHost, pgPort, maxConnections, timeout, shouldDisplayLog=false),
  dbopen(MariaDB, database, user, password, mariadbHost, mysqlPort, maxConnections, timeout, shouldDisplayLog=false),
]

let dbConnectionsTransacion* = @[
  dbopen(SQLite3, sqliteHost, maxConnections=95, timeout=timeout, shouldDisplayLog=false),
  dbopen(PostgreSQL, database, user, password, pgHost, pgPort, maxConnections, timeout, shouldDisplayLog=false),
  dbopen(MariaDB, database, user, password, mariadbHost, mysqlPort, maxConnections, timeout, shouldDisplayLog=false),
]

template asyncBlock*(body:untyped) =
  waitFor (proc(){.async.}=
    body
  )()
