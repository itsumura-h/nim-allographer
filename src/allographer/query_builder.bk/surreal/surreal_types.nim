import std/asyncdispatch
import std/json
import std/times
import std/strutils
import ../error
import ../log
import ./databases/surreal_rdb

type
  SurrealDb* = ref object
    conn*: SurrealConnections
    log*: LogSetting
    query*: JsonNode
    queryString*: string
    placeHolder*: seq[string]
    # for transaction
    isInTransaction*:bool
    transactionConn*:int

  RawQuerySurrealDb* = ref object
    conn*: SurrealConnections
    log*: LogSetting
    query*: JsonNode
    queryString*: string
    placeHolder*: seq[string]
    # for transaction
    isInTransaction*:bool
    transactionConn*:int


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


const errorConnectionNum* = 99999


proc getFreeConn*(self:SurrealConnections):Future[int] {.async.} =
  let calledAt = getTime().toUnix()
  while true:
    for i in 0..<self.pools.len:
      if not self.pools[i].isBusy:
        self.pools[i].isBusy = true
        # echo "=== getFreeConn ", i
        return i
        break
    await sleepAsync(10)
    if getTime().toUnix() >= calledAt + self.timeout:
      return errorConnectionNum


proc returnConn*(self: SurrealConnections, i: int) {.async.} =
  if i != errorConnectionNum:
    self.pools[i].isBusy = false
