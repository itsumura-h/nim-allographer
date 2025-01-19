import std/asyncdispatch
import std/strformat
import ../../../query_builder/models/postgres/postgres_query
import ../../../query_builder/models/postgres/postgres_exec
import ../../models/table
import ./postgres_query_type


proc resetMigrationTable*(self:PostgresSchema) =
  self.rdb.table("_allographer_migrations").where("name", "=", self.table.name).delete().waitFor

proc resetTable*(self:PostgresSchema) =
  self.rdb.raw(&"DROP TABLE IF EXISTS \"{self.table.name}\"").exec().waitFor
