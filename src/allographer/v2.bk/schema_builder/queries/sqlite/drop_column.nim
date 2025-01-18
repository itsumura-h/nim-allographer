import std/asyncdispatch
import std/strutils
import std/strformat
import std/sequtils
import std/re
import checksums/sha1
import std/json
import ../../../query_builder/models/sqlite/sqlite_query
import ../../../query_builder/models/sqlite/sqlite_exec
import ../../models/table
import ../../models/column
import  ./schema_utils
import ./sqlite_query_type


proc dropColumn*(self:SqliteSchema, isReset:bool) =
  ## - create tmp table with new column difinition
  ## - copy data from old table to tmp table
  ## - delete old table
  ## - rename tmp table name to old table name
  
  let tableDifinitionSql = &"SELECT sql FROM sqlite_master WHERE type = 'table' AND name = '{self.table.name}'"
  var rows = self.rdb.raw(tableDifinitionSql).get().waitFor
  let schema = replace(rows[0]["sql"].getStr, re"\)$", ",)")

  var queries:seq[string] = @[]
  var columnRegex = &"'{self.column.name}'\\s+.*?,"
  var query = schema.replace(re(columnRegex), "")
  query = query.replace(re",\s*\)$", ")")
  query = query.replace(re("CREATE TABLE \"\\w+\""), &"CREATE TABLE \"alter_{self.table.name}\"")
  queries.add(query)

  var columns = self.rdb.table(self.table.name).columns().waitFor
  columns = columns.filter(
    proc(x:string):bool =
      return x != self.column.name
  )
  for i, row in columns:
    columns[i] = &"'{row}'"
  let columnsString = columns.join(", ")
  query = &"INSERT INTO \"alter_{self.table.name}\"({columnsString}) SELECT {columnsString} FROM \"{self.table.name}\""
  queries.add(query)
  # delete existing table
  query = &"DROP TABLE IF EXISTS \"{self.table.name}\""
  queries.add(query)
  # rename tmp table to existing table
  query = &"ALTER TABLE \"alter_{self.table.name}\" RENAME TO \"{self.table.name}\""
  queries.add(query)
  let jsonSchema = $self.column.toSchema()
  let checksum = $jsonSchema.secureHash()

  if shouldRun(self.rdb, self.table, checksum, isReset):
    execThenSaveHistory(self.rdb, self.table.name, queries, checksum)
