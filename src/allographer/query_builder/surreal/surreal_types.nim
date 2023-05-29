import std/asyncdispatch
import std/json
import std/times
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
