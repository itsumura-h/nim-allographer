import std/strformat
import std/sha1
import std/json
import ../../models/table
import ./mysql_query_type
import ../schema_utils


proc renameTable*(self:MysqlSchema, isReset:bool) =
  let query = &"RENAME TABLE `{self.table.previousName}` TO `{self.table.name}`"
  let schema = $self.table.toSchema()
  let checksum = $schema.secureHash()

  if shouldRun(self.rdb, self.table, checksum, isReset):
    execThenSaveHistory(self.rdb, self.table.name, query, checksum)
