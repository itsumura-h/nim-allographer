import strformat, strutils, json, asyncdispatch, times
import ../../base
import
  ../table,
  ../column
import ./migrate_interface
import ../generators/sqlite_generators
import ../../query_builder


proc isExistsTable*(table:string):string =
  return sqlite_generators.isExistsTableQuery(table)

proc generateColumnString*(column:Column):string =
  var columnString = ""
  case column.typ:
  # int ===================================================================
  of rdbIncrements:
    columnString.add(
      serialGenerator(column.name)
    )
  of rdbInteger:
    columnString.add(
      intGenerator(
        column.name,
        column.isNullable,
        column.isUnique,
        column.isUnsigned,
        column.isDefault,
        column.defaultInt,
      )
    )
  of rdbSmallInteger:
    columnString.add(
      intGenerator(
        column.name,
        column.isNullable,
        column.isUnique,
        column.isUnsigned,
        column.isDefault,
        column.defaultInt,
      )
    )
  of rdbMediumInteger:
    columnString.add(
      intGenerator(
        column.name,
        column.isNullable,
        column.isUnique,
        column.isUnsigned,
        column.isDefault,
        column.defaultInt,
      )
    )
  of rdbBigInteger:
    columnString.add(
      intGenerator(
        column.name,
        column.isNullable,
        column.isUnique,
        column.isUnsigned,
        column.isDefault,
        column.defaultInt,
      )
    )
  # float =================================================================
  of rdbDecimal:
    columnString.add(
      decimalGenerator(
        column.name,
        parseInt($column.info["maximum"]),
        parseInt($column.info["digit"]),
        column.isNullable,
        column.isUnique,
        column.isUnsigned,
        column.isDefault,
        column.defaultFloat,
      )
    )
  of rdbDouble:
    columnString.add(
      decimalGenerator(
        column.name,
        parseInt($column.info["maximum"]),
        parseInt($column.info["digit"]),
        column.isNullable,
        column.isUnique,
        column.isUnsigned,
        column.isDefault,
        column.defaultFloat,
      )
    )
  of rdbFloat:
    columnString.add(
      floatGenerator(
        column.name,
        column.isNullable,
        column.isUnique,
        column.isUnsigned,
        column.isDefault,
        column.defaultFloat,
      )
    )
  # char ==================================================================
  of rdbChar:
    columnString.add(
      charGenerator(
        column.name,
        parseInt($column.info["maxLength"]),
        column.isNullable,
        column.isUnique,
        column.isUnsigned,
        column.isDefault,
        column.defaultString,
      )
    )
  of rdbString:
    columnString.add(
      varcharGenerator(
        column.name,
        parseInt($column.info["maxLength"]),
        column.isNullable,
        column.isUnique,
        column.isUnsigned,
        column.isDefault,
        column.defaultString,
      )
    )
  # text ==================================================================
  of rdbText:
    columnString.add(
      textGenerator(
        column.name,
        column.isNullable,
        column.isUnique,
        column.isUnsigned,
        column.isDefault,
        column.defaultString,
      )
    )
  of rdbMediumText:
    columnString.add(
      textGenerator(
        column.name,
        column.isNullable,
        column.isUnique,
        column.isUnsigned,
        column.isDefault,
        column.defaultString,
      )
    )
  of rdbLongText:
    columnString.add(
      textGenerator(
        column.name,
        column.isNullable,
        column.isUnique,
        column.isUnsigned,
        column.isDefault,
        column.defaultString,
      )
    )
  # date ==================================================================
  of rdbDate:
    columnString.add(
      dateGenerator(
        column.name,
        column.isNullable,
        column.isUnique,
        column.isUnsigned,
        column.isDefault,
      )
    )
  of rdbDatetime:
    columnString.add(
      datetimeGenerator(
        column.name,
        column.isNullable,
        column.isUnique,
        column.isUnsigned,
        column.isDefault,
      )
    )
  of rdbTime:
    columnString.add(
      timeGenerator(
        column.name,
        column.isNullable,
        column.isUnique,
        column.isUnsigned,
        column.isDefault,
      )
    )
  of rdbTimestamp:
    columnString.add(
      timestampGenerator(
        column.name,
        column.isNullable,
        column.isUnique,
        column.isUnsigned,
        column.isDefault,
      )
    )
  of rdbTimestamps:
    columnString.add(
      timestampsGenerator()
    )
  of rdbSoftDelete:
    columnString.add(
      softDeleteGenerator()
    )
  # others ================================================================
  of rdbBinary:
    columnString.add(
      blobGenerator(
        column.name,
        column.isNullable,
        column.isUnique,
        column.isUnsigned,
        column.isDefault,
        column.defaultString,
      )
    )
  of rdbBoolean:
    columnString.add(
      boolGenerator(
        column.name,
        column.isNullable,
        column.isUnique,
        column.isUnsigned,
        column.isDefault,
        column.defaultBool,
      )
    )
  of rdbEnumField:
    columnString.add(
      enumGenerator(
        column.name,
        column.info["options"].getElems,
        column.isNullable,
        column.isUnique,
        column.isUnsigned,
        column.isDefault,
        column.defaultString,
      )
    )
  of rdbJson:
    columnString.add(
      jsonGenerator(
        column.name,
        column.isNullable,
        column.isUnique,
        column.isUnsigned,
        column.isDefault,
        column.defaultJson,
      )
    )
  of rdbForeign:
    columnString.add(
      foreignColumnGenerator(column.name, column.isDefault, column.defaultInt)
    )
  of rdbStrForeign:
    columnString.add(
      strForeignColumnGenerator(column.name, column.isDefault, column.defaultString)
    )
  return columnString

proc generateForeignString(column:Column):string =
  if column.typ == rdbForeign or column.typ == rdbStrForeign:
    return foreignGenerator(
      column.name,
      column.info["table"].getStr(),
      column.info["column"].getStr(),
      column.foreignOnDelete
    )

proc generateAlterForeignString(column:Column):string =
  if column.typ == rdbForeign or column.typ == rdbStrForeign:
    return alterAddForeignGenerator(
      column.info["table"].getStr(),
      column.info["column"].getStr(),
    )

type SqliteMigrate* = ref object
  rdb: Rdb

proc new*(_:type SqliteMigrate, rdb:Rdb):SqliteMigrate =
  return SqliteMigrate(rdb:rdb)

proc migrateSql(self:SqliteMigrate, table:Table):string =
  var columnString = ""
  var foreignString = ""
  for i, column in table.columns:
    if i > 0: columnString.add(", ")
    columnString.add(
      generateColumnString(column)
    )
    if column.typ == rdbForeign or column.typ == rdbStrForeign:
      if columnString.len > 0 or foreignString.len > 0: foreignString.add(", ")
      foreignString.add(
        generateForeignString(column)
      )

  return &"CREATE TABLE IF NOT EXISTS \"{table.name}\" ({columnString}{foreignString})"

proc createIndex(self:SqliteMigrate, table, column:string):(string, string) =
  return (indexGenerate(table, column), indexName(table, column))

# proc createIndex(self:SqliteMigrate, table, column:string):string =
#   return indexGenerate(table, column)

proc dropTableQuery(self:SqliteMigrate, tableName:string):string =
  return &"DROP TABLE IF EXISTS {tableName}"

proc dropIndexQuery(self:SqliteMigrate, indexName:string):string =
  return &"DROP INDEX IF EXISTS {indexName}"

proc saveHistoryQuery(
  self:SqliteMigrate,
  query, txHash:string,
  status:bool,
  runAt:string
):string =
  return self.rdb.table("allographer_migrations").insertSql(%*{
    "query": query,
    "tx_id":txHash,
    "status": status,
    "run_at": runAt
  })

proc migrateAlter(self:SqliteMigrate, column:Column, table:string):string =
  let columnString = generateColumnString(column)
  let foreignString = generateAlterForeignString(column)

  if foreignString.len > 0:
    return &"ALTER TABLE \"{table}\" ADD COLUMN {columnString} {foreignString}"
  else:
    return &"ALTER TABLE \"{table}\" ADD COLUMN {columnString}"

proc toInterface*(self:SqliteMigrate):IMigrate =
  return (
    migrateSql:proc(table:Table):string = self.migrateSql(table),
    createIndex:proc(table, column:string):(string, string) = self.createIndex(table, column),
    # createIndex:proc(table, column:string):string = self.createIndex(table, column),
    dropTableQuery:proc(tableName:string):string = self.dropTableQuery(tableName),
    dropIndexQuery:proc(indexName:string):string = self.dropIndexQuery(indexName),
    saveHistoryQuery:proc(query, txHash:string, status:bool, runAt:string):string =
      self.saveHistoryQuery(query, txHash, status, runAt),
    migrateAlter:proc(column:Column, table:string):string = self.migrateAlter(column, table),
  )
