import std/sha1
import std/json
import ../../models/table
import ../../models/column
import ./schema_utils
import ./mysql_query_type
import ./sub/add_column_query


proc addColumn*(self:MysqlSchema, isReset:bool) =
  let queries = addColumnString(self.table, self.column)
  
  let schema = $self.column.toSchema()
  let checksum = $schema.secureHash()

  if shouldRun(self.rdb, self.table, checksum, isReset):
    execThenSaveHistory(self.rdb, self.table.name, queries, checksum)
