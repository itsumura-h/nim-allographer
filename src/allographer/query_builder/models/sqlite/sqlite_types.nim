import std/json
import ../../log
import ../../libs/sqlite/sqlite_rdb


type SQLite3* = object


type SqliteConnection* = object
  conn*: PSqlite3
  isBusy*: bool
  createdAt*: int64


## created by `let rdb = dbOpen(SQLite3, "/path/to/sqlite.db")`
type SqliteConnections* = object
  log*: LogSetting
  pools*:seq[SqliteConnection]
  timeout*:int


## created by `rdb.select("columnName")` or `rdb.table("tableName")`
type SqliteQuery* = ref object
  log*: LogSetting
  pools*:seq[SqliteConnection]
  timeout*:int
  query*: JsonNode
  queryString*: string
  placeHolder*: JsonNode # [{"key":"user", "value":"user1"}]
  # for transaction
  isInTransaction*: bool
  transactionConn*: int


type RawSqliteQuery* = ref object
  log*: LogSetting
  pools*:seq[SqliteConnection]
  timeout*:int
  query*: JsonNode
  queryString*: string
  placeHolder*: JsonNode # ["user1", "user1@example.com"]
  # for transaction
  isInTransaction*: bool
  transactionConn*: int
