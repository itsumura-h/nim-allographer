import std/asyncdispatch
import std/json
import ./query_builder/log
import ./query_builder/models/sqlite/sqlite_types
import ./query_builder/models/sqlite/sqlite_open
import ./query_builder/models/postgres/postgres_types
import ./query_builder/models/postgres/postgres_open

export
  SQLite3,
  PostgreSQL


proc dbOpen*(driver:type SQLite3, database="", user="", password="",
            host="", port:int32=0, maxConnections=1, timeout=30,
            shouldDisplayLog=false, shouldOutputLogFile=false, logDir=""):SqliteConnections =
  result = sqliteOpen(database, user, password, host, port, maxConnections, timeout)
  result.log = LogSetting(shouldDisplayLog:shouldDisplayLog, shouldOutputLogFile:shouldOutputLogFile, logDir:logDir)


proc dbOpen*(driver:type PostgreSQL, database="", user="", password="",
            host="", port:int32=0, maxConnections=1, timeout=30,
            shouldDisplayLog=false, shouldOutputLogFile=false, logDir=""):PostgresConnections =
  result = postgresOpen(database, user, password, host, port, maxConnections, timeout)
  result.log = LogSetting(shouldDisplayLog:shouldDisplayLog, shouldOutputLogFile:shouldOutputLogFile, logDir:logDir)
