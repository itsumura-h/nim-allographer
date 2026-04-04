import std/tables
import std/json
import ../../log
import ../../libs/mysql/mysql_rdb


type MySQL* = object


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


type MysqlPreparedEntry* = ref object
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
  preparedCache*: Table[string, MysqlPreparedEntry]


## created by `let rdb = dbOpen(MySQL, "localhost", 3306)`
type MysqlConnections* = ref object
  log*: LogSetting
  pools*:Connections
  info*:ConnectionInfo
  # for transaction
  isInTransaction*: bool
  transactionConn*: int


type MysqlPreparedContext* = ref object
  owner*: MysqlConnections
  connI*: int


## created by `rdb.select("columnName")` or `rdb.table("tableName")`
type MysqlQuery* = ref object
  log*: LogSetting
  pools*:Connections
  info*:ConnectionInfo
  query*: JsonNode
  queryString*: string
  placeHolder*: JsonNode # [{"key":"user", "value":"user1"}]
  # for transaction
  isInTransaction*: bool
  transactionConn*: int


type RawMysqlQuery* = ref object
  log*: LogSetting
  pools*:Connections
  info*:ConnectionInfo
  query*: JsonNode
  queryString*: string
  placeHolder*: JsonNode # ["user1", "user1@example.com"]
  # for transaction
  isInTransaction*: bool
  transactionConn*: int


type MysqlResultBindCache* = ref object
  binds*: seq[BIND]
  buffers*: seq[string]
  lengths*: seq[culong]
  nullFlags*: seq[my_bool]
  errorFlags*: seq[my_bool]


type MysqlPreparedStatement* = ref object
  owner*: MysqlConnections
  info*: ConnectionInfo
  entry*: MysqlPreparedEntry
  sql*: string
  nArgs*: int
  isClosed*: bool
  resultBindCache*: seq[MysqlResultBindCache]


proc `$`*(self:MysqlConnections|MysqlQuery|RawMysqlQuery):string =
  return "MySQL"


proc isConnected*(self:MysqlConnections|MysqlQuery|RawMysqlQuery):bool =
  return self.pools.conns.len > 0
