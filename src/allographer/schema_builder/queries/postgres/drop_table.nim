import std/strformat
import std/json
import std/sha1
import ../../models/table
import ../query_utils
import ./postgres_query_type


proc dropTable*(self:PostgresQuery, isReset:bool) =
  let query = &"DROP TABLE IF EXISTS \"{self.table.name}\""
  let schema = $self.table.toSchema()
  let checksum = $schema.secureHash()
  if shouldRun(self.rdb, self.table, checksum, isReset):
    execThenSaveHistory(self.rdb, self.table.name, query, checksum)