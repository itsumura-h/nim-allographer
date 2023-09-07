import std/asyncdispatch
import std/strformat
import ../../../query_builder
import ../../models/table
import ./postgres_query_type


proc resetMigrationTable*(self:PostgresSchema) =
  self.rdb.table("allographer_migrations").where("name", "=", self.table.name).delete.waitFor

proc resetTable*(self:PostgresSchema) =
  self.rdb.raw(&"DROP TABLE IF EXISTS \"{self.table.name}\"").exec.waitFor
