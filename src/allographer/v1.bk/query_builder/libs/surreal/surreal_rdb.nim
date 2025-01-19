import std/httpclient

type SurrealConn* = object
  client*: AsyncHttpClient
  host*:string
  port*:int32
