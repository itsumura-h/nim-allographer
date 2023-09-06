import std/json
import ../../log
import ../../libs/mariadb/mariadb_rdb


type MariaDB* = object

type MariadbConnectionInfo* = object
  database*:string
  user*:string
  password*:string
  host*:string
  port*:int

type MariadbConnection* = object
  conn*: PMySQL
  isBusy*: bool
  createdAt*: int64
  info*:MariadbConnectionInfo

## created by `let rdb = dbOpen(MySQL, "localhost", 3306)`
type MariadbConnections* = ref object
  log*: LogSetting
  pools*:seq[MariadbConnection]
  timeout*:int
  # for transaction
  isInTransaction*: bool
  transactionConn*: int

proc `$`*(self:MariadbConnections):string =
  return "MariaDB"


## created by `rdb.select("columnName")` or `rdb.table("tableName")`
type MariadbQuery* = ref object
  log*: LogSetting
  pools*:seq[MariadbConnection]
  timeout*:int
  query*: JsonNode
  queryString*: string
  placeHolder*: JsonNode # [{"key":"user", "value":"user1"}]
  # for transaction
  isInTransaction*: bool
  transactionConn*: int


type RawMariadbQuery* = ref object
  log*: LogSetting
  pools*:seq[MariadbConnection]
  timeout*:int
  query*: JsonNode
  queryString*: string
  placeHolder*: JsonNode # ["user1", "user1@example.com"]
  # for transaction
  isInTransaction*: bool
  transactionConn*: int