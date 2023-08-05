import std/strformat
import std/sha1
import std/json
import ../../models/table
import ./sqlite_query_type
import ../schema_utils


proc dropTable*(self:SqliteSchema, isReset:bool) =
  let query = &"DROP TABLE IF EXISTS \"{self.table.name}\""
  let schema = $self.table.toSchema()
  let checksum = $schema.secureHash()

  if shouldRun(self.rdb, self.table, checksum, isReset):
    execThenSaveHistory(self.rdb, self.table.name, query, checksum)
