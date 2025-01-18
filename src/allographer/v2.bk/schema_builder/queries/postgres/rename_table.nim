import std/strformat
import checksums/sha1
import std/json
import ../../models/table
import ./postgres_query_type
import ./schema_utils


proc renameTable*(self:PostgresSchema, isReset:bool) =
  let query = &"ALTER TABLE \"{self.table.previousName}\" RENAME TO \"{self.table.name}\""
  let schema = $self.table.toSchema()
  let checksum = $schema.secureHash()

  if shouldRun(self.rdb, self.table, checksum, isReset):
    execThenSaveHistory(self.rdb, self.table.name, query, checksum)
