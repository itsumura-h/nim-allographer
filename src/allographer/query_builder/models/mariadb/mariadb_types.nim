import std/asyncdispatch
import std/deques
import std/json
import std/tables
import ../../log
import ../../libs/mariadb/mariadb_rdb


type MariaDB* = object


const DEFAULT_CONN_MAX_LIFETIME_SECONDS* = 300
const DEFAULT_CONN_MAX_IDLE_SECONDS* = 300


type ConnectionInfo* = object
  database*:string
  user*:string
  password*:string
  host*:string
  port*:int


type Connection* = object
  conn*: PMySQL
  isBusy*: bool
  createdAt*: int64
  lastUsedAt*: int64


type MariadbPreparedEntry* = ref object
  sql*: string
  nArgs*: int
  stmts*: seq[PSTMT]
  refCount*: int
  lastUsedAt*: int64


type Connections* = ref object
  conns*: seq[Connection]
  timeout*:int
  maxConnectionLifetime*: int
  maxConnectionIdleTime*: int
  info*: ConnectionInfo
  waiters*: Deque[Future[void]]
  columnTypeCache*: Table[string, seq[seq[string]]]
  preparedCache*: Table[string, MariadbPreparedEntry]


## created by `let rdb = dbOpen(MySQL, "localhost", 3306)`
type MariadbConnections* = ref object
  log*: LogSetting
  pools*:Connections
  info*:ConnectionInfo
  # for transaction
  isInTransaction*: bool
  transactionConn*: int


type MariadbPreparedContext* = ref object
  owner*: MariadbConnections
  connI*: int


## created by `rdb.select("columnName")` or `rdb.table("tableName")`
type MariadbQuery* = ref object
  log*: LogSetting
  pools*:Connections
  info*:ConnectionInfo
  query*: JsonNode
  queryString*: string
  placeHolder*: JsonNode # [{"key":"user", "value":"user1"}]
  # for transaction
  isInTransaction*: bool
  transactionConn*: int


type RawMariadbQuery* = ref object
  log*: LogSetting
  pools*:Connections
  info*:ConnectionInfo
  query*: JsonNode
  queryString*: string
  placeHolder*: JsonNode # ["user1", "user1@example.com"]
  # for transaction
  isInTransaction*: bool
  transactionConn*: int


type MariadbResultBindCache* = ref object
  binds*: seq[BIND]
  buffers*: seq[string]
  lengths*: seq[culong]
  nullFlags*: seq[my_bool]
  errorFlags*: seq[my_bool]


type MariadbPreparedStatement* = ref object
  owner*: MariadbConnections
  info*: ConnectionInfo
  entry*: MariadbPreparedEntry
  sql*: string
  nArgs*: int
  isClosed*: bool
  resultBindCache*: seq[MariadbResultBindCache]




proc `$`*(self:MariadbConnections|MariadbQuery|RawMariadbQuery):string =
  return "MariaDB"


proc isConnected*(self:MariadbConnections|MariadbQuery|RawMariadbQuery):bool =
  return self.pools.conns.len > 0
