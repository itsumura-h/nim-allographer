## https://surrealdb.com/docs/surrealql/statements/define/table

# import std/asyncdispatch
import std/strformat
import std/strutils
# import std/sha1
# import std/json
# import ../../../query_builder
# import ../../enums
import ../../models/table
# import ../../models/column
import ../schema_utils
import ./surreal_query_type
import ./sub/create_column_query


proc createMigrationTable*(self: SurrealSchema) =
  var queries:seq[string]
  queries.add(&"DEFINE TABLE `{self.table.name}` SCHEMAFULL")
  
  for i, column in self.table.columns:
    queries.add(createColumnString(self.table, column))

  let query = queries.join("; ")
  exec(self.rdb, @[query])
