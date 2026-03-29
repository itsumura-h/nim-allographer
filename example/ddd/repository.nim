import json
import std/asyncdispatch
import std/options
import ../../src/allographer/query_builder
import ../connections

type Repository* = ref object
  rdb*: SqliteConnections

proc newRepository*(): Repository =
  Repository(rdb: rdb)

proc getUsers*(this: Repository): seq[JsonNode] =
  this.rdb.table("users").get().waitFor()

proc getUser*(this: Repository, id: int): Option[JsonNode] =
  this.rdb.table("users").find(id).waitFor()
