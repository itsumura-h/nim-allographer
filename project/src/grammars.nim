import base
import json

proc table*(this: RDB, tableArg: string): RDB =
  this.query = %*{"table": tableArg}
  return this

proc select*(this: RDB, columnsArg: varargs[string]): RDB =
  if columnsArg.len == 0:
    this.query["select"] = %["*"]
  else:
    this.query["select"] = %*columnsArg
  
  return this