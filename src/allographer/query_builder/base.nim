import json
import ../async/async_db

type Rdb* = ref object
  db*: Connections
  query*: JsonNode
  sqlString*: string
  placeHolder*: seq[string]

proc cleanUp*(self:Rdb) =
  self.query = newJNull()
  self.sqlString = ""
  self.placeHolder = newSeq[string]()
