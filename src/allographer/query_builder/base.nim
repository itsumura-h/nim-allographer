import json
import ../connection

when getDriver() == "postgres":
  type
    RDB* = ref object of RootObj
      db*: DbConn
      pool*: AsyncPool
      query*: JsonNode
      sqlString*: string
      placeHolder*: seq[string]
else:
  type
    RDB* = ref object of RootObj
      db*: DbConn
      query*: JsonNode
      sqlString*: string
      placeHolder*: seq[string]

proc isNil*[DbConn](x: DbConn): bool {.noSideEffect, magic: "IsNil".}

proc cleanUp*(this:RDB) =
  this.query = newJNull()
  this.sqlString = ""
  this.placeHolder = newSeq[string]()
