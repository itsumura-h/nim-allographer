import json


type
  RDB* = ref object of RootObj
    query*: JsonNode
    sqlString*: string
    sqlStringSeq*: seq[string]
