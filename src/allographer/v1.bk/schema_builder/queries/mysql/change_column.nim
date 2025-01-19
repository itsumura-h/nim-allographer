import std/asyncdispatch
import std/json
import std/strformat
import std/sha1
import ../../models/table
import ../../models/column
import ./schema_utils
import ./mysql_query_type
import ./sub/change_column_query
import ./sub/is_exists


proc changeColumn*(self:MysqlSchema, isReset:bool) =
  let schema = $self.column.toSchema()
  let checksum = $schema.secureHash()

  var queries:seq[string]
  if isExistsUnique(self.rdb, self.table, self.column).waitFor():
    queries.add(&"ALTER TABLE `{self.table.name}` DROP INDEX `{self.column.name}`") # unique
  if isExistsIndex(self.rdb, self.table, self.column).waitFor():
    queries.add(&"ALTER TABLE `{self.table.name}` DROP INDEX `{self.table.name}_{self.column.name}_index`")
  queries.add(
    changeColumnString(self.table, self.column)
  )

  if self.column.isIndex:
    let indexQuery = addIndexString(self.column, self.table)
    queries.add(indexQuery)

  if shouldRun(self.rdb, self.table, checksum, isReset):
    execThenSaveHistory(self.rdb, self.table.name, queries, checksum)
