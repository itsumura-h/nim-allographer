import json
import ../../src/allographer/query_builder

type Repository* = ref object
  rdb:RDB

proc newRepository*():Repository =
  return Repository(rdb:rdb())

proc getUsers*(this:Repository):seq[JsonNode] =
  return this.rdb.table("users").get()

proc getUser*(this:Repository, id:int):JsonNode =
  return this.rdb.table("users").find(id)
