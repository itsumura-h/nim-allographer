import std/strformat
import std/strutils
import std/sequtils
import std/sha1
import std/json
import ../../enums
import ../../models/table
import ../../models/column
import ./postgres_query_type
import ./sub/create_column_query
import ./schema_utils


proc createTable*(self: PostgresSchema, isReset:bool) =
  var queries:seq[string] = @[]
  var query = ""
  var foreignQuery = ""
  var indexQuery:seq[string] = @[]
  var updatedAtQuery:seq[string] = @[]

  for i, column in self.table.columns:
    if query.len > 0: query.add(", ")
    query.add(createColumnString(self.table, column))
    
    if column.typ == rdbForeign or column.typ == rdbStrForeign:
      if foreignQuery.len > 0:  foreignQuery.add(", ")
      foreignQuery.add(createForeignString(self.table, column))
    
    if column.isIndex:
      indexQuery.add(createIndexString(self.table, column))

    if column.isUpdatedAt:
      updatedAtQuery.add(createUpdatedAtString(self.table, column))

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

  if updatedAtQuery.len > 0:
    queries.add(updatedAtQuery)

  let schema = $self.table.toSchema()
  let checksum = $schema.secureHash()

  if shouldRun(self.rdb, self.table, checksum, isReset):
    execThenSaveHistory(self.rdb, self.table.name, queries, checksum)
