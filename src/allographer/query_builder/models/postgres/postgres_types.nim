import std/asyncdispatch
import std/deques
import std/json
import std/tables
import ../database_types
import ../../log
import ../../libs/postgres/postgres_rdb


type PostgreSQL* = object


const DEFAULT_CONN_MAX_LIFETIME_SECONDS* = 300
const DEFAULT_CONN_MAX_IDLE_SECONDS* = 300


type Connection* = ref object
  conn*: PPGconn
  isBusy*: bool
  createdAt*: int64
  lastUsedAt*: int64


type PostgresPreparedEntry* = ref object
  sql*: string
  nArgs*: int
  stmtBaseName*: string
  stmtNames*: seq[string]
  refCount*: int
  lastUsedAt*: int64


type Connections* = ref object
  conns*: seq[Connection]
  timeout*: int
  maxConnectionLifetime*: int
  maxConnectionIdleTime*: int
  database*: string
  user*: string
  password*: string
  host*: string
  port*: int
  ## `getFreeConn` が接続を待つときに積む Future。`returnConn` が先頭から 1 件だけ完了させる。
  waiters*: Deque[Future[void]]
  ## `exec` / `insertId` 用。テーブルごとに information_schema 相当の列型を初回のみ取得して保持する。
  columnTypeCache*: Table[string, seq[Row]]
  ## SQL 単位の prepared statement cache。物理 prepare 状態は conn ごとに保持する。
  preparedCache*: Table[string, PostgresPreparedEntry]


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


type PostgresPreparedContext* = ref object
  owner*: PostgresConnections
  connI*: int


type PostgresPreparedStatement* = ref object
  owner*: PostgresConnections
  entry*: PostgresPreparedEntry
  sql*: string
  nArgs*: int
  isClosed*: bool


proc `$`*(self:PostgresConnections|PostgresQuery|RawPostgresQuery):string =
  return "PostgreSQL"


proc isConnected*(self:PostgresConnections|PostgresQuery|RawPostgresQuery):bool =
  return self.pools.conns.len > 0
