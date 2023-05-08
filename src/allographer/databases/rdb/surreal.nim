import std/httpclient

type
  SurrealConn* = object
    conn*:AsyncHttpClient
    host*:string
    port*:int32
