import std/asyncdispatch
import std/strformat
import ../../../query_builder
import ../../models/table
import ./mariadb_query_type


proc resetMigrationTable*(self:MariadbSchema) =
  self.rdb.table("allographer_migrations").where("name", "=", self.table.name).delete.waitFor

proc resetTable*(self:MariadbSchema) =
  self.rdb.raw(&"DROP TABLE IF EXISTS `{self.table.name}`").exec.waitFor
