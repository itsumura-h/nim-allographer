when NimMajor >= 2:
  import checksums/sha1
else:
  import std/sha1

import std/strformat
import std/json
import ../../models/table
import ./schema_utils
import ./postgres_query_type


proc dropTable*(self:PostgresSchema, isReset:bool) =
  let query = &"DROP TABLE IF EXISTS \"{self.table.name}\""
  let schema = $self.table.toSchema()
  let checksum = $schema.secureHash()
  if shouldRun(self.rdb, self.table, checksum, isReset):
    execThenSaveHistory(self.rdb, self.table.name, query, checksum)
