import std/httpclient
import std/json


type
  SurrealConn* = object
    conn*:AsyncHttpClient
    host*:string
    port*:int32
    isBusy*:bool
    createdAt*:int64

  SurrealConnections* = ref object
    pools*: seq[SurrealConn]
    timeout*:int

  
  SurrealDb* = ref object
    conn*: SurrealConnections
    log*: LogSetting
    query*: JsonNode
    sqlString*: string
    placeHolder*: seq[string]
    # for transaction
    isInTransaction*:bool
    transactionConn*:int
