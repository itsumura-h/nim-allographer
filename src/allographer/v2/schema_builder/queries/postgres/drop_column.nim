import std/json
import std/strformat
import checksums/sha1
import ../../models/table
import ../../models/column
import ./schema_utils
import ./postgres_query_type


proc dropColumn*(self:PostgresSchema, isReset:bool) =
  let query = &"ALTER TABLE \"{self.table.name}\" DROP COLUMN \"{self.column.name}\""
  let schema = $self.column.toSchema()
  let checksum = $schema.secureHash()
  if shouldRun(self.rdb, self.table, checksum, isReset):
    execThenSaveHistory(self.rdb, self.table.name, query, checksum)