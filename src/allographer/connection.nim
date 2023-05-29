import std/asyncdispatch
import std/json
import ./query_builder/log
import ./query_builder/rdb/rdb_types
import ./query_builder/rdb/query/exec
import ./query_builder/surreal/surreal_types
import ./query_builder/surreal/databases/surreal_impl

export
  Driver,
  SurrealDb

proc dbOpen*(driver:Driver, database="", user="", password="",
            host="", port=0, maxConnections=1, timeout=30,
            shouldDisplayLog=false, shouldOutputLogFile=false, logDir=""):Rdb =
  result = new Rdb
  result.driver = driver
  result.conn = open(driver, database, user, password, host, port, maxConnections, timeout)
  result.log = LogSetting(shouldDisplayLog:shouldDisplayLog, shouldOutputLogFile:shouldOutputLogFile, logDir:logDir)
  result.query = newJObject()
  result.isInTransaction = false

proc dbOpen*(_:type SurrealDb, namespace="", database="", user="", password="",
            host="", port=0, maxConnections=1, timeout=30,
            shouldDisplayLog=false, shouldOutputLogFile=false, logDir=""):Future[SurrealDb] {.async.} =
  result = new SurrealDb
  result.conn = await SurrealImpl.open(namespace, database, user, password, host, port.int32, maxConnections, timeout)
  result.log = LogSetting(shouldDisplayLog:shouldDisplayLog, shouldOutputLogFile:shouldOutputLogFile, logDir:logDir)
  result.query = newJObject()
  result.isInTransaction = false
