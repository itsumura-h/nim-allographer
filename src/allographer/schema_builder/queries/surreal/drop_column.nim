import std/json
import std/strformat
import std/sha1
import ../../models/table
import ../../models/column
import ./schema_utils
import ./surreal_query_type


proc dropColumn*(self:SurrealSchema, isReset:bool) =
  let query = &"REMOVE FIELD `{self.column.name}` ON TABLE `{self.table.name}`"
  let schema = $self.column.toSchema()
  let checksum = $schema.secureHash()
  if shouldRun(self.rdb, self.table, checksum, isReset):
    execThenSaveHistory(self.rdb, self.table.name, query, checksum)
