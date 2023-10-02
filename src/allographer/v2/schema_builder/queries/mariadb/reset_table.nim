import std/asyncdispatch
import std/strformat
import ../../../query_builder/models/mariadb/mariadb_connections
import ../../../query_builder/models/mariadb/mariadb_query
import ../../models/table
import ./mariadb_query_type


proc resetMigrationTable*(self:MariadbSchema) =
  self.rdb.table("_allographer_migrations").where("name", "=", self.table.name).delete.waitFor

proc resetTable*(self:MariadbSchema) =
  self.rdb.raw(&"DROP TABLE IF EXISTS `{self.table.name}`").exec.waitFor
