import std/strformat
import ../../enums
import ../../models/table
import ../../models/column
import ./schema_utils
import ./mariadb_query_type
import ./sub/create_column_query


proc createMigrationTable*(self: MariadbSchema) =
  var queries:seq[string] = @[]
  var query = ""
  var foreignQuery = ""
  var indexQuery:seq[string] = @[]
  for i, column in self.table.columns:
    if query.len > 0: query.add(", ")
    query.add(createColumnString(self.table, column))
    
    if column.typ == rdbForeign or column.typ == rdbStrForeign:
      if foreignQuery.len > 0:  foreignQuery.add(", ")
      foreignQuery.add(createForeignKey(self.table, column))
    
    if column.isIndex:
      indexQuery.add(createIndexString(self.table, column))

  if foreignQuery.len > 0:
    queries.add(
      &"CREATE TABLE IF NOT EXISTS `{self.table.name}` ({query}, {foreignQuery})"
    )
  else:
    queries.add(
      &"CREATE TABLE IF NOT EXISTS `{self.table.name}` ({query})"
    )

  if indexQuery.len > 0:
    queries.add(indexQuery)

  exec(self.rdb, queries)
