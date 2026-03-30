import std/asyncdispatch
import std/deques
import std/json
import std/tables
import ../database_types
import ../../log
import ../../libs/postgres/postgres_rdb


type PostgreSQL* = object


type Connection* = ref object
  conn*: PPGconn
  isBusy*: bool
  createdAt*: int64


type Connections* = ref object
  conns*: seq[Connection]
  timeout*: int
  ## `getFreeConn` が接続を待つときに積む Future。`returnConn` が先頭から 1 件だけ完了させる。
  waiters*: Deque[Future[void]]
  ## `exec` / `insertId` 用。テーブルごとに information_schema 相当の列型を初回のみ取得して保持する。
  columnTypeCache*: Table[string, seq[Row]]


## created by `let rdb = dbOpen(PostgreSQL, "localhost", 5432)`
type PostgresConnections* = ref object
  log*: LogSetting
  pools*:Connections
  # for transaction
  isInTransaction*: bool
  transactionConn*: int


## created by `rdb.select("columnName")` or `rdb.table("tableName")`
type PostgresQuery* = ref object
  log*: LogSetting
  pools*:Connections
  query*: JsonNode # JObject
  queryString*: string
  placeHolder*: JsonNode # JArray [{"key":"user", "value":"user1"}]
  # for transaction
  isInTransaction*: bool
  transactionConn*: int


type RawPostgresQuery* = ref object
  log*: LogSetting
  pools*:Connections
  query*: JsonNode
  queryString*: string
  placeHolder*: JsonNode # JArray ["user1", "user1@example.com"]
  # for transaction
  isInTransaction*: bool
  transactionConn*: int


type PostgresPreparedStatement* = ref object
  owner*: PostgresConnections
  sql*: string
  stmtBaseName*: string
  stmtNames*: seq[string]
  nArgs*: int


proc `$`*(self:PostgresConnections|PostgresQuery|RawPostgresQuery):string =
  return "PostgreSQL"


proc isConnected*(self:PostgresConnections|PostgresQuery|RawPostgresQuery):bool =
  return self.pools.conns.len > 0
