when NimMajor >= 2:
  import checksums/sha1
else:
  import std/sha1

import std/strformat
import std/strutils
import std/sequtils
import std/json
import ../../enums
import ../../models/table
import ../../models/column
import ./schema_utils
import ./sqlite_query_type
import ./sub/create_column_query


proc createTable*(self: SqliteSchema, isReset:bool) =
  var queries:seq[string] = @[]
  var query = ""
  var foreignQuery = ""
  var indexQuery:seq[string] = @[]

  for i, column in self.table.columns:
    if query.len > 0: query.add(", ")
    query.add(createColumnString(column))
    
    if column.typ == rdbForeign or column.typ == rdbStrForeign:
      if foreignQuery.len > 0:  foreignQuery.add(", ")
      foreignQuery.add(createForeignString(column))
    
    if column.isIndex:
      indexQuery.add(createIndexString(self.table, column))

  if self.table.primary.len > 0:
    let primary = self.table.primary.map(
        proc(row:string):string =
          return &"\"{row}\""
      )
      .join(", ")
    query.add(&", PRIMARY KEY({primary})")

  if foreignQuery.len > 0:
    queries.add(
      &"CREATE TABLE IF NOT EXISTS \"{self.table.name}\" ({query}, {foreignQuery})"
    )
  else:
    queries.add(
      &"CREATE TABLE IF NOT EXISTS \"{self.table.name}\" ({query})"
    )

  if indexQuery.len > 0:
    queries.add(indexQuery)

  let schema = $self.table.toSchema()
  let checksum = $schema.secureHash()

  if shouldRun(self.rdb, self.table, checksum, isReset):
    execThenSaveHistory(self.rdb, self.table.name, queries, checksum)
