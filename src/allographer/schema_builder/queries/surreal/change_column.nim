when NimMajor >= 2:
  from db_connector/db_common import DbError
else:
  from std/db_common import DbError

# import checksums/sha1
# import std/json
import std/strformat
# import ../../models/table
# import ../../models/column
# import ../../enums
# import ./schema_utils
import ./surreal_query_type
# import ./sub/change_column_query


proc changeColumn*(self:SurrealSchema, isReset:bool) =
  ## SurrealDB not support change column field
  ## 
  ## https://github.com/surrealdb/surrealdb/issues/1838
  
  raise newException(DbError, &"SurrealDB not support change column field. see also: https://github.com/surrealdb/surrealdb/issues/1838")

  # var queries = changeColumnString(self.table, self.column)
  
  # if self.column.isIndex and self.column.typ != rdbIncrements:
  #   queries.add(changeIndexString(self.table, self.column))

  # let schema = $self.column.toSchema()
  # let checksum = $schema.secureHash()

  # if shouldRun(self.rdb, self.table, checksum, isReset):
  #   execThenSaveHistory(self.rdb, self.table.name, queries, checksum)
