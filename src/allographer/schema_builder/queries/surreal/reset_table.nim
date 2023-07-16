import std/asyncdispatch
import std/strformat
import ../../../query_builder
import ../../models/table
import ./surreal_query_type


proc resetMigrationTable*(self:SurrealQuery) =
  self.rdb.table("_migrations").where("name", "=", self.table.name).delete.waitFor

proc resetTable*(self:SurrealQuery) =
  self.rdb.raw(&"REMOVE TABLE `{self.table.name}`").exec.waitFor
