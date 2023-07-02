import std/asyncdispatch
import std/strformat
import ../../../query_builder/rdb/rdb_interface
import ../../../query_builder/rdb/query/grammar
import ../../models/table
import ./sqlite_query_type

proc resetMigrationTable*(self:SqliteQuery) =
  self.rdb.table("_migrations").where("name", "=", self.table.name).delete.waitFor

proc resetTable*(self:SqliteQuery) =
  self.rdb.raw(&"DROP TABLE IF EXISTS \"{self.table.name}\"").exec.waitFor
