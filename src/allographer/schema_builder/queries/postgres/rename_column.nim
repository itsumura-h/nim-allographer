when NimMajor >= 2:
  import checksums/sha1
else:
  import std/sha1

import std/strformat
import std/json
import ../../models/table
import ../../models/column
import ./schema_utils
import ./postgres_query_type


proc renameColumn*(self:PostgresSchema, isReset:bool) =
  let query = &"ALTER TABLE \"{self.table.name}\" RENAME COLUMN \"{self.column.previousName}\" TO \"{self.column.name}\""
  let schema = $self.column.toSchema()
  let checksum = $schema.secureHash()
  if shouldRun(self.rdb, self.table, checksum, isReset):
    execThenSaveHistory(self.rdb, self.table.name, query, checksum)
