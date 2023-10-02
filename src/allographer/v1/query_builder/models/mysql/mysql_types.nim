import std/json
import ../../log
import ../../libs/mysql/mysql_rdb


type MySQL* = object

type MysqlConnectionInfo* = object
  database*:string
  user*:string
  password*:string
  host*:string
  port*:int

type MysqlConnection* = object
  conn*: PMySQL
  isBusy*: bool
  createdAt*: int64

## created by `let rdb = dbOpen(MySQL, "localhost", 3306)`
type MysqlConnections* = ref object
  log*: LogSetting
  pools*:seq[MysqlConnection]
  timeout*:int
  info*:MysqlConnectionInfo
  # for transaction
  isInTransaction*: bool
  transactionConn*: int

proc `$`*(self:MysqlConnections):string =
  return "MySQL"


## created by `rdb.select("columnName")` or `rdb.table("tableName")`
type MysqlQuery* = ref object
  log*: LogSetting
  pools*:seq[MysqlConnection]
  timeout*:int
  info*:MysqlConnectionInfo
  query*: JsonNode
  queryString*: string
  placeHolder*: JsonNode # [{"key":"user", "value":"user1"}]
  # for transaction
  isInTransaction*: bool
  transactionConn*: int


type RawMysqlQuery* = ref object
  log*: LogSetting
  pools*:seq[MysqlConnection]
  timeout*:int
  info*:MysqlConnectionInfo
  query*: JsonNode
  queryString*: string
  placeHolder*: JsonNode # ["user1", "user1@example.com"]
  # for transaction
  isInTransaction*: bool
  transactionConn*: int
