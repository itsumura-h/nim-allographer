import std/strformat
import std/sha1
import std/json
import ../../models/table
import ../../models/column
import ./schema_utils
import ./mysql_query_type


proc dropColumn*(self:MysqlSchema, isReset:bool) =
  let query = &"ALTER TABLE `{self.table.name}` DROP COLUMN `{self.column.name}`"
  let schema = $self.column.toSchema()
  let checksum = $schema.secureHash()
  if shouldRun(self.rdb, self.table, checksum, isReset):
    execThenSaveHistory(self.rdb, self.table.name, query, checksum)
