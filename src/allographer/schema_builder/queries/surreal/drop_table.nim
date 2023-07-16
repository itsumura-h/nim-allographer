import std/json
import std/strformat
import std/sha1
import ../../models/table
import ../query_utils
import ./surreal_query_type


proc dropTable*(self:SurrealQuery, isReset:bool) =
  let query = &"REMOVE TABLE `{self.table.name}`"
  let schema = $self.table.toSchema()
  let checksum = $schema.secureHash()
  if shouldRun(self.rdb, self.table, checksum, isReset):
    execThenSaveHistory(self.rdb, self.table.name, query, checksum)
