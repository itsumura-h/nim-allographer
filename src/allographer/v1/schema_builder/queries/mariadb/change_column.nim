import std/strformat
import std/sha1
import std/json
import ../../models/table
import ../../models/column
import ./schema_utils
import ./mariadb_query_type
import ./sub/change_column_query


proc changeColumn*(self:MariadbSchema, isReset:bool) =
  let schema = $self.column.toSchema()
  let checksum = $schema.secureHash()

  var queries:seq[string]
  queries.add(&"ALTER TABLE `{self.table.name}` DROP INDEX IF EXISTS `{self.column.name}`") # unique
  queries.add(&"ALTER TABLE `{self.table.name}` DROP INDEX IF EXISTS `{self.table.name}_{self.column.name}_index`")
  queries.add(
    changeColumnString(self.table, self.column)
  )

  if self.column.isIndex:
    let indexQuery = addIndexString(self.column, self.table)
    queries.add(indexQuery)

  if shouldRun(self.rdb, self.table, checksum, isReset):
    execThenSaveHistory(self.rdb, self.table.name, queries, checksum)
