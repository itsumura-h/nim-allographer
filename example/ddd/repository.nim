import json
import ../../src/allographer/query_builder

type Repository* = ref object
  rdb:RDB

proc newRepository*(db:DbConn):Repository =
  return Repository(rdb:RDB(db:db))

proc getUsers*(this:Repository):seq[JsonNode] =
  return this.rdb.table("users").get()
