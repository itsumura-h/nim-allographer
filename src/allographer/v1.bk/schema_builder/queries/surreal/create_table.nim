## https://surrealdb.com/docs/surrealql/statements/define/table

import std/strformat
import std/strutils
import std/sha1
import std/json
import ../../models/table
import ./schema_utils
import ./surreal_query_type
import ./sub/create_column_query


proc createTable*(self: SurrealSchema, isReset:bool) =
  var queries:seq[string]
  queries.add(&"DEFINE TABLE `{self.table.name}` SCHEMAFULL")

  for i, column in self.table.columns:
    queries.add(createColumnString(self.table, column))

  let schema = $self.table.toSchema()
  let checksum = $schema.secureHash()
  let query = queries.join("; ")

  if shouldRun(self.rdb, self.table, checksum, isReset):
    execThenSaveHistory(self.rdb, self.table.name, query, checksum)
