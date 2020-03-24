import json
import ../connection

type
  RDB* = ref object of RootObj
    db*: DbConn
    query*: JsonNode
    sqlString*: string
    sqlStringSeq*: seq[string]
    placeHolder*: seq[string]
