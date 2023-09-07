import std/asyncdispatch
import std/json
import ./query_builder/log
import ./query_builder/models/sqlite/sqlite_types
import ./query_builder/models/sqlite/sqlite_open
import ./query_builder/models/postgres/postgres_types
import ./query_builder/models/postgres/postgres_open
import ./query_builder/models/mariadb/mariadb_types
import ./query_builder/models/mariadb/mariadb_open
import ./query_builder/models/mysql/mysql_types
import ./query_builder/models/mysql/mysql_open

export
  SQLite3,
  PostgreSQL,
  MariaDB,
  MySql


proc dbOpen*(driver:type SQLite3, database="", user="", password="",
            host="", port:int32=0, maxConnections=1, timeout=30,
            shouldDisplayLog=false, shouldOutputLogFile=false, logDir=""):SqliteConnections =
  result = sqliteOpen(database, user, password, host, port, maxConnections, timeout)
  result.log = LogSetting(shouldDisplayLog:shouldDisplayLog, shouldOutputLogFile:shouldOutputLogFile, logDir:logDir)


proc dbOpen*(driver:type PostgreSQL, database="", user="", password="",
            host="", port=0, maxConnections=1, timeout=30,
            shouldDisplayLog=false, shouldOutputLogFile=false, logDir=""):PostgresConnections =
  result = postgresOpen(database, user, password, host, port.int32, maxConnections, timeout)
  result.log = LogSetting(shouldDisplayLog:shouldDisplayLog, shouldOutputLogFile:shouldOutputLogFile, logDir:logDir)


proc dbOpen*(driver:type MariaDB, database="", user="", password="",
            host="", port=0, maxConnections=1, timeout=30,
            shouldDisplayLog=false, shouldOutputLogFile=false, logDir=""):MariadbConnections =
  result = mariadbOpen(database, user, password, host, port.int32, maxConnections, timeout)
  result.log = LogSetting(shouldDisplayLog:shouldDisplayLog, shouldOutputLogFile:shouldOutputLogFile, logDir:logDir)


proc dbOpen*(driver:type MySql, database="", user="", password="",
            host="", port=0, maxConnections=1, timeout=30,
            shouldDisplayLog=false, shouldOutputLogFile=false, logDir=""):MysqlConnections =
  result = mysqlOpen(database, user, password, host, port.int32, maxConnections, timeout)
  result.log = LogSetting(shouldDisplayLog:shouldDisplayLog, shouldOutputLogFile:shouldOutputLogFile, logDir:logDir)
