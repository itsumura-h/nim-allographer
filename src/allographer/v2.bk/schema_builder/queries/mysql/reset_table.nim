import std/asyncdispatch
import std/strformat
import ../../../query_builder/models/mysql/mysql_query
import ../../../query_builder/models/mysql/mysql_exec
import ../../models/table
import ./mysql_query_type


proc resetMigrationTable*(self:MysqlSchema) =
  self.rdb.table("_allographer_migrations").where("name", "=", self.table.name).delete().waitFor

proc resetTable*(self:MysqlSchema) =
  self.rdb.raw(&"DROP TABLE IF EXISTS `{self.table.name}`").exec().waitFor
