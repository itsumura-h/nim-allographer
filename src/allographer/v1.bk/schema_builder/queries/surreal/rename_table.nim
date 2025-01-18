from std/db_common import DbError
import std/strformat
# import std/sha1
# import std/json
# import ../../models/table
import ./surreal_query_type
# import ./schema_utils


proc renameTable*(self:SurrealSchema, isReset:bool) =
  ## SurrealDB not support rename table field
  ## 
  ## https://github.com/surrealdb/surrealdb/issues/1615

  raise newException(DbError, &"SurrealDB not support rename table field. see also: https://github.com/surrealdb/surrealdb/issues/1615")


  # let query = &"ALTER TABLE \"{self.table.previousName}\" RENAME TO \"{self.table.name}\""
  # let schema = $self.table.toSchema()
  # let checksum = $schema.secureHash()

  # if shouldRun(self.rdb, self.table, checksum, isReset):
  #   execThenSaveHistory(self.rdb, self.table.name, query, checksum)
