when NimMajor >= 2:
  from db_connector/db_common import DbError
else:
  from std/db_common import DbError

import std/strformat
# import checksums/sha1
# import std/json
# import ../../models/table
# import ../../models/column
# import ./schema_utils
import ./surreal_query_type


proc renameColumn*(self:SurrealSchema, isReset:bool) =
  ## SurrealDB not support rename column field
  ## 
  ## https://github.com/surrealdb/surrealdb/issues/1615

  raise newException(DbError, &"SurrealDB not support rename column field. see also: https://github.com/surrealdb/surrealdb/issues/1615")

  # let query = &"ALTER TABLE \"{self.table.name}\" RENAME COLUMN \"{self.column.previousName}\" TO \"{self.column.name}\""
  # let schema = $self.column.toSchema()
  # let checksum = $schema.secureHash()
  # if shouldRun(self.rdb, self.table, checksum, isReset):
  #   execThenSaveHistory(self.rdb, self.table.name, query, checksum)
