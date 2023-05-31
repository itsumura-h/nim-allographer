import std/httpclient


type SurrealConn* = object
  conn*:AsyncHttpClient
  host*:string
  port*:int32
  isBusy*:bool
  createdAt*:int64


type SurrealConnections* = ref object
  pools*: seq[SurrealConn]
  timeout*:int
