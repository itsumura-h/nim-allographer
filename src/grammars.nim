import base
import json

proc table*(this: DBObject, tableArg: string): DBObject =
    this.query = %*{"table": tableArg}
    return this