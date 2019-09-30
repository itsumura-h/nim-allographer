import json


type DBObject* = ref object of RootObj
  query*: JsonNode
