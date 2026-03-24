## https://surrealdb.com/docs/surrealql/statements/define/table

import std/asyncdispatch
import std/strformat
import std/strutils
import std/json
import ../../../query_builder/models/surreal/surreal_types
import ../../../query_builder/models/surreal/surreal_query
import ../../../query_builder/models/surreal/surreal_exec
import ../../models/table
import ./schema_utils
import ./surreal_query_type
import ./sub/create_column_query


proc createMigrationTable*(self: SurrealSchema, isReset: bool = false) =
  let logDisplay = self.rdb.log.shouldDisplayLog
  let logFile = self.rdb.log.shouldOutputLogFile
  self.rdb.log.shouldDisplayLog = false
  self.rdb.log.shouldOutputLogFile = false
  defer:
    self.rdb.log.shouldDisplayLog = logDisplay
    self.rdb.log.shouldOutputLogFile = logFile

  let info = self.rdb.raw("INFO FOR DB").info().waitFor()
  var hasMigrationTable = info[0]["result"]["tables"].contains("_allographer_migrations")
  if isReset and hasMigrationTable:
    self.rdb.raw("REMOVE TABLE `_allographer_migrations`").exec().waitFor()
    hasMigrationTable = false

  if not hasMigrationTable:
    var queries:seq[string]
    queries.add(&"DEFINE TABLE `{self.table.name}` SCHEMAFULL")
    
    for i, column in self.table.columns:
      queries.add(createColumnString(self.table, column))

    let query = queries.join("; ")
    exec(self.rdb, @[query])
