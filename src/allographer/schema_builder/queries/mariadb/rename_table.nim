when NimMajor >= 2:
  import checksums/sha1
else:
  import std/sha1

import std/strformat
import std/json
import ../../models/table
import ./mariadb_query_type
import ./schema_utils


proc renameTable*(self:MariadbSchema, isReset:bool) =
  let query = &"RENAME TABLE `{self.table.previousName}` TO `{self.table.name}`"
  let schema = $self.table.toSchema()
  let checksum = $schema.secureHash()

  if shouldRun(self.rdb, self.table, checksum, isReset):
    execThenSaveHistory(self.rdb, self.table.name, query, checksum)
