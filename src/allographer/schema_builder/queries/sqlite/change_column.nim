import std/asyncdispatch
import std/strutils
import std/strformat
import std/re
import std/sha1
import std/options
import std/json
import std/times
import ../../../query_builder
import ../../enums
import ../../models/table
import ../../models/column
import ./sqlite_query_type
import ./sub/create_column_query


proc shouldRun(rdb:Rdb, table:Table, checksum:string, isReset:bool):bool =
  if isReset:
    return true

  # let tables = rdb.table("_migrations")
  #           .where("name", "=", table.name)
  #           .orderBy("created_at", Desc)
  #           .get()
  #           .waitFor

  # var histories = newJObject()
  # for table in tables:
  #   histories[table["checksum"].getStr] = table

  # if not histories.hasKey(checksum):
  #   return true

  # return not histories[checksum]["status"].getBool
  let history = rdb.table("_migrations")
                  .where("checksum", "=", checksum)
                  .first()
                  .waitFor
  return not history.isSome() or not history.get()["status"].getBool


proc execThenSaveHistory(rdb:Rdb, tableName:string, queries:seq[string], checksum:string) =
  var isSuccess = false
  try:
    for query in queries:
      rdb.raw(query).exec.waitFor
    isSuccess = true
  except:
    echo getCurrentExceptionMsg()

  let tableQuery = queries.join("; ")
  rdb.table("_migrations").insert(%*{
    "name": tableName,
    "query": tableQuery,
    "checksum": checksum,
    "created_at": $now().utc,
    "status": isSuccess
  })
  .waitFor


proc changeColumn*(self:SqliteQuery, isReset:bool) =
  ## - create tmp table with new column difinition
  ## - copy data from old table to tmp table
  ## - delete old table
  ## - rename tmp table name to old table name
  let tableDifinitionSql = &"SELECT sql FROM sqlite_master WHERE type = 'table' AND name = '{self.table.name}'"
  var rows = self.rdb.raw(tableDifinitionSql).get.waitFor
  let schema = replace(rows[0]["sql"].getStr, re"\)$", ",)")

  var queries:seq[string] = @[]
  let columnRegex = &"'{self.column.name}'\\s+.*?,"
  createColumnString(self.column)
  createForeignString(self.column)
  var query = schema.replace(re(columnRegex), self.column.query & ",")
  if self.column.foreignQuery.len > 0:
    query = query.replace(re",\s*\)", &" , {self.column.foreignQuery},)")
  query = query.replace(re",\s*\)$", ")")
  query = query.replace(re("CREATE TABLE \"\\w+\""), &"CREATE TABLE \"alter_{self.table.name}\"")
  queries.add(query)

  # copy data from existing table to tmp table
  query = &"INSERT INTO \"alter_{self.table.name}\" SELECT * FROM \"{self.table.name}\""
  queries.add(query)
  # delete existing table
  query = &"DROP TABLE IF EXISTS \"{self.table.name}\""
  queries.add(query)
  # rename tmp table to existing table
  query = &"ALTER TABLE \"alter_{self.table.name}\" RENAME TO \"{self.table.name}\""
  queries.add(query)
  let jsonSchema = $self.column.toSchema()
  let checksum = $jsonSchema.secureHash()

  if shouldRun(self.rdb, self.table, checksum, isReset):
    execThenSaveHistory(self.rdb, self.table.name, queries, checksum)
