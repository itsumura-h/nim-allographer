import json


type RDB* = ref object of RootObj
  query*: JsonNode
  sqlStringSeq*: seq[string]
