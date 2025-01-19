when NimMajor >= 2:
  import checksums/sha1
else:
  import std/sha1

import std/json
import ../../models/table
import ../../models/column
import ../../enums
import ./schema_utils
import ./postgres_query_type
import ./sub/change_column_query


proc changeColumn*(self:PostgresSchema, isReset:bool) =
  var queries = changeColumnString(self.table, self.column)
  
  if self.column.isIndex and self.column.typ != rdbIncrements:
    queries.add(changeIndexString(self.table, self.column))

  let schema = $self.column.toSchema()
  let checksum = $schema.secureHash()

  if shouldRun(self.rdb, self.table, checksum, isReset):
    execThenSaveHistory(self.rdb, self.table.name, queries, checksum)
