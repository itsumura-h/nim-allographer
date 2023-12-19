import std/asyncdispatch
import std/strformat
import ../../../query_builder/models/surreal/surreal_query
import ../../../query_builder/models/surreal/surreal_exec
import ../../models/table
import ./surreal_query_type


proc resetMigrationTable*(self:SurrealSchema) =
  self.rdb.table("_allographer_migrations").where("name", "=", self.table.name).delete().waitFor

proc resetTable*(self:SurrealSchema) =
  self.rdb.raw(&"REMOVE TABLE `{self.table.name}`").exec().waitFor
