import std/json
import std/httpclient
import ../../log
import ../../libs/surreal/surreal_rdb
import ../../error


type SurrealDB* = object


type SurrealConnection* = object
  conn*:SurrealConn
  isBusy*:bool
  createdAt*:int64


## created by `let rdb = dbOpen(SurrealDB, "ns", "database", "user", "pass", "http://surreal", 8000)`
type SurrealConnections* = ref object
  log*: LogSetting
  pools*:seq[SurrealConnection]
  timeout*:int


proc `$`*(self:SurrealConnections):string =
  return "SurrealDB"


type SurrealQuery* = ref object
  ## created by `rdb.select("columnName")` or `rdb.table("tableName")`
  log*: LogSetting
  pools*:seq[SurrealConnection]
  timeout*:int
  query*: JsonNode
  queryString*: string
  # placeHolder*: JsonNode # JArray [{"key":"user", "value":"user1"}]
  placeHolder*: JsonNode # JArray [true, 1, 1.1, "str"]

proc new*(_:type SurrealQuery, log:LogSetting, pools:seq[SurrealConnection], timeout:int, query:JsonNode):SurrealQuery =
  return SurrealQuery(
    log:log,
    pools:pools,
    timeout:timeout,
    query:query,
    queryString:"",
    placeHolder: newJArray()
  )


type RawSurrealQuery* = ref object
  log*: LogSetting
  pools*:seq[SurrealConnection]
  timeout*:int
  query*: JsonNode
  queryString*: string
  placeHolder*: JsonNode # JArray ["user1", "user1@example.com"]


type SurrealId* = object
  table*:string
  id:string


proc new*(_:type SurrealId):SurrealId =
  ## create empty surreal id
  return SurrealId(table:"", id:"")


proc new*(_:type SurrealId, table, id:string):SurrealId =
  ## .. code-block:: Nim
  ##  let rawId = "user:z7cr4mz474h4ab7rcd6d"
  ##  let table = "user"
  ##  let id = "z7cr4mz474h4ab7rcd6d"
  ##  let surrealId = SureealId.new(table, id)
  if table.len == 0:
    dbError("table cannot be empty")
  if id.len == 0:
    dbError("id cannot be empty")
  return SurrealId(table:table, id:id)


proc new*(_:type SurrealId, rawId:string):SurrealId =
  ## .. code-block:: Nim
  ##  let rawId = "user:z7cr4mz474h4ab7rcd6d"
  ##  let surrealId = SureealId.new(rawId)
  if rawId.len == 0:
    dbError("rawId cannot be empty")
  let split = rawId.split(":")
  let table = split[0]
  let id = split[1]
  return SurrealId(table:table, id:id)


proc rawId*(self:SurrealId):string =
  ## .. code-block:: Nim
  ##  let rawId = "user:z7cr4mz474h4ab7rcd6d"
  ##  let surrealId = SureealId.new(rawId) 
  ##  surrealId.rawId() == "user:z7cr4mz474h4ab7rcd6d"
  return self.table & ":" & self.id


proc `$`*(self:SurrealId):string =
  return self.id


proc `%`*(self:SurrealId):JsonNode =
  return %(self.rawId())
