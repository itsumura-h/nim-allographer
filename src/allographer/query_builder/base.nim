import json
import database
import ../connection

type
  Rdb* = ref object of RootObj
    db*: DBConnection
    query*: JsonNode
    sqlString*: string
    placeHolder*: seq[string]

# proc isNil*[DbConn](x: DbConn): bool {.noSideEffect, magic: "IsNil".}

proc cleanUp*(self:RDB) =
  self.query = newJNull()
  self.sqlString = ""
  self.placeHolder = newSeq[string]()
