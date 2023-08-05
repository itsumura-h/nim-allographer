import std/asyncdispatch
import std/json
import ./query_builder/log
import ./query_builder/models/sqlite/sqlite_types
import ./query_builder/models/sqlite/sqlite_open
import ./query_builder/models/sqlite/sqlite_connections

export
  SQLite3


proc dbOpen*(driver:type SQLite3, database="", user="", password="",
            host="", port:int32=0, maxConnections=1, timeout=30,
            shouldDisplayLog=false, shouldOutputLogFile=false, logDir=""):SqliteConnections =
  result = sqliteOpen(database, user, password, host, port, maxConnections, timeout)
  result.log = LogSetting(shouldDisplayLog:shouldDisplayLog, shouldOutputLogFile:shouldOutputLogFile, logDir:logDir)
