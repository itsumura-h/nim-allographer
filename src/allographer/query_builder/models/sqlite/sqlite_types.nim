import std/asyncdispatch
import std/deques
import std/json
import std/tables
import ../../log
import ../../libs/sqlite/sqlite_rdb


type SQLite3* = object


type Connection* = ref object
  conn*: PSqlite3
  isBusy*: bool
  createdAt*: int64


type Connections* = ref object
  conns*: seq[Connection]
  timeout*: int
  ## `getFreeConn` が接続を待つときに積む Future。`returnConn` が先頭から 1 件だけ完了させる。
  waiters*: Deque[Future[void]]
  ## `exec` / `insertId` 用。テーブルごとに PRAGMA table_info の結果を初回のみ保持する。
  columnTypeCache*: Table[string, seq[(string, string)]]


## created by `let rdb = dbOpen(SQLite3, "/path/to/sqlite.db")`
type SqliteConnections* = ref object
  log*: LogSetting
  pools*:Connections
  # for transaction
  isInTransaction*: bool
  transactionConn*: int


## created by `rdb.select("columnName")` or `rdb.table("tableName")`
type SqliteQuery* = ref object
  log*: LogSetting
  pools*:Connections
  query*: JsonNode # JObject
  queryString*: string
  placeHolder*: JsonNode # JArray [{"key":"user", "value":"user1"}]
  # for transaction
  isInTransaction*: bool
  transactionConn*: int


type RawSqliteQuery* = ref object
  log*: LogSetting
  pools*:Connections
  query*: JsonNode # JObject
  queryString*: string
  placeHolder*: JsonNode # JArray ["user1", "user1@example.com"]
  # for transaction
  isInTransaction*: bool
  transactionConn*: int


proc `$`*(self:SqliteConnections|SqliteQuery|RawSqliteQuery):string =
  return "SQLite"
