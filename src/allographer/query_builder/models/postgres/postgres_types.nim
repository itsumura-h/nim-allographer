import std/json
import ../../log
import ../../libs/postgres/postgres_rdb


type PostgreSQL* = object


type PostgresConnection* = object
  conn*: PPGconn
  isBusy*: bool
  createdAt*: int64


## created by `let rdb = dbOpen(PostgreSQL, "localhost", 5432)`
type PostgresConnections* = ref object
  log*: LogSetting
  pools*:seq[PostgresConnection]
  timeout*:int
  # for transaction
  isInTransaction*: bool
  transactionConn*: int

proc `$`*(self:PostgresConnections):string =
  return "PostgreSQL"


## created by `rdb.select("columnName")` or `rdb.table("tableName")`
type PostgresQuery* = ref object
  log*: LogSetting
  pools*:seq[PostgresConnection]
  timeout*:int
  query*: JsonNode
  queryString*: string
  placeHolder*: JsonNode # [{"key":"user", "value":"user1"}]
  # for transaction
  isInTransaction*: bool
  transactionConn*: int


type RawPostgresQuery* = ref object
  log*: LogSetting
  pools*:seq[PostgresConnection]
  timeout*:int
  query*: JsonNode
  queryString*: string
  placeHolder*: JsonNode # ["user1", "user1@example.com"]
  # for transaction
  isInTransaction*: bool
  transactionConn*: int