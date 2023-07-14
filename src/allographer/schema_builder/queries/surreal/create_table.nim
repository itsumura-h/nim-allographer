## https://surrealdb.com/docs/surrealql/statements/define/table

import std/asyncdispatch
import std/strformat
import std/strutils
import std/sha1
import std/json
import ../../../query_builder
import ../../enums
import ../../models/table
import ../../models/column
import ../query_utils
import ./surreal_query_type
import ./sub/create_column_query


proc createTable*(self: SurrealQuery, isReset:bool) =
  echo "===== createTable"
  var queries:seq[string]
  queries.add(&"DEFINE TABLE `{self.table.name}` SCHEMAFULL")
  
  for i, column in self.table.columns:
    queries.add(createColumnString(self.table, column))

  let schema = $self.table.toSchema()
  let checksum = $schema.secureHash()
  let query = queries.join("; ")
  execThenSaveHistory(self.rdb, self.table.name, query, checksum)


  # var queries:seq[string] = @[]
  # var query = ""
  # var foreignQuery = ""
  # var indexQuery:seq[string] = @[]

  # for i, column in self.table.columns:
  #   if query.len > 0: query.add(", ")
  #   query.add(createColumnString(column))
    
  #   if column.typ == rdbForeign or column.typ == rdbStrForeign:
  #     if foreignQuery.len > 0:  foreignQuery.add(", ")
  #     foreignQuery.add(createForeignString(column))
    
  #   if column.isIndex:
  #     indexQuery.add(createIndexString(self.table, column))

  # if foreignQuery.len > 0:
  #   queries.add(
  #     &"DEFINE TABLE IF NOT EXISTS \"{self.table.name}\" ({query}, {foreignQuery})"
  #   )
  # else:
  #   queries.add(
  #     &"DEFINE TABLE IF NOT EXISTS \"{self.table.name}\" ({query})"
  #   )

  # if indexQuery.len > 0:
  #   queries.add(indexQuery)

  # let schema = $self.table.toSchema()
  # let checksum = $schema.secureHash()

  # if shouldRun(self.rdb, self.table, checksum, isReset):
  #   execThenSaveHistory(self.rdb, self.table.name, queries, checksum)
