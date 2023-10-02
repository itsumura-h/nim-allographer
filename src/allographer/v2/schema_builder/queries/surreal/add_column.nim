import std/json
import checksums/sha1
import ../../models/table
import ../../models/column
import ./schema_utils
import ./surreal_query_type
import ./sub/create_column_query


proc addColumn*(self:SurrealSchema, isReset:bool) =
  let queries = createColumnString(self.table, self.column)
  
  let schema = $self.column.toSchema()
  let checksum = $schema.secureHash()

  if shouldRun(self.rdb, self.table, checksum, isReset):
    execThenSaveHistory(self.rdb, self.table.name, queries, checksum)
