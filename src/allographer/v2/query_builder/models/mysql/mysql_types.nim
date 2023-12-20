import std/json
import ../../log
import ../../libs/mysql/mysql_rdb


type MySQL* = object


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


type Connections* = ref object
  conns*: seq[Connection]
  timeout*:int


## created by `let rdb = dbOpen(MySQL, "localhost", 3306)`
type MysqlConnections* = ref object
  log*: LogSetting
  pools*:Connections
  info*:ConnectionInfo
  # for transaction
  isInTransaction*: bool
  transactionConn*: int


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


proc `$`*(self:MysqlConnections|MysqlQuery|RawMysqlQuery):string =
  return "MySQL"
