## https://www.sqlite.org/lang_createtable.html#constraints

import std/asyncdispatch
import std/json
import std/strformat
import std/strutils
import std/re
import ../../../../query_builder/models/sqlite/sqlite_types
import ../../../../query_builder/models/sqlite/sqlite_query
import ../../../../query_builder/models/sqlite/sqlite_exec
import ../../../models/table
import ../../../models/column
import ../../../enums
import ../schema_utils
import ./create_column_query

# =============================================================================
# int
# =============================================================================
proc addSerialColumn(rdb:SqliteConnections, table:Table, column:Column, query:string):seq[string] =
  # get culumn definition
  let tableDifinitionSql = &"SELECT sql FROM sqlite_master WHERE type = 'table' AND name = '{table.name}'"
  var rows = rdb.raw(tableDifinitionSql).get().waitFor
  let schema = replace(rows[0]["sql"].getStr, re"\)$", ",)")
  var query = schema.replace(re",\)", &", {query},)")
  query = query.replace(re",\)", ")")
  query = query.replace(re("CREATE TABLE \"\\w+\""), &"CREATE TABLE \"alter_{table.name}\"")
  result.add(query)
  # copy data from existing table to tmp table
  var columns = rdb.table(table.name).columns().waitFor
  for i, row in columns:
    columns[i] = &"'{row}'"
  let columnsString = columns.join(", ")
  query = &"INSERT INTO \"alter_{table.name}\"({columnsString}) SELECT {columnsString} FROM \"{table.name}\""
  result.add(query)
  # delete existing table
  query = &"DROP TABLE IF EXISTS \"{table.name}\""
  result.add(query)
  # rename tmp table to existing table
  query = &"ALTER TABLE \"alter_{table.name}\" RENAME TO \"{table.name}\""
  result.add(query)


proc addIntColumn(table:Table, column:Column):seq[string] =
  var query = &"ALTER TABLE \"{table.name}\" ADD COLUMN '{column.name}' INTEGER"

  if not column.isNullable:
    query.add(" NOT NULL")

  if column.isDefault:
    query.add(&" DEFAULT {column.defaultInt}")

  if column.isUnsigned:
    query.add(&" CHECK ({column.name} >= 0)")

  return @[query]


# =============================================================================
# float
# =============================================================================
proc addDecimalColumn(table:Table, column:Column):seq[string] =
  var query = &"ALTER TABLE \"{table.name}\" ADD COLUMN '{column.name}' NUMERIC"

  if not column.isNullable:
    query.add(" NOT NULL")

  if column.isDefault:
    query.add(&" DEFAULT {column.defaultFloat}")

  if column.isUnsigned:
    query.add(&" CHECK ({column.name} >= 0)")

  return @[query]


proc addFloatColumn(table:Table, column:Column):seq[string] =
  var query = &"ALTER TABLE \"{table.name}\" ADD COLUMN '{column.name}' REAL"

  if not column.isNullable:
    query.add(" NOT NULL")

  if column.isDefault:
    query.add(&" DEFAULT {column.defaultFloat}")

  if column.isUnsigned:
    query.add(&" CHECK ({column.name} >= 0)")

  return @[query]


# =============================================================================
# char
# =============================================================================
proc addUuidColumn(table:Table, column:Column):seq[string] =
  var query = &"ALTER TABLE \"{table.name}\" ADD COLUMN '{column.name}' VARCHAR"

  if not column.isNullable:
    query.add(" NOT NULL")

  if column.isDefault:
    query.add(&" DEFAULT '{column.defaultString}'")

  let maxLength = column.info["maxLength"].getInt
  query.add(&" CHECK (length('{column.name}') <= {maxLength})")

  if column.isUnsigned:
    notAllowedOption("unsigned", "varchar", column.name)

  return @[query]


proc addCharColumn(table:Table, column:Column):seq[string] =
  var query = &"ALTER TABLE \"{table.name}\" ADD COLUMN '{column.name}' VARCHAR"

  if not column.isNullable:
    query.add(" NOT NULL")

  if column.isDefault:
    query.add(&" DEFAULT '{column.defaultString}'")

  let maxLength = column.info["maxLength"].getInt
  query.add(&" CHECK (length('{column.name}') <= {maxLength})")

  if column.isUnsigned:
    notAllowedOption("unsigned", "char", column.name)

  return @[query]


proc addVarcharColumn(table:Table, column:Column):seq[string] =
  var query = &"ALTER TABLE \"{table.name}\" ADD COLUMN '{column.name}' VARCHAR"

  if not column.isNullable:
    query.add(" NOT NULL")

  if column.isDefault:
    query.add(&" DEFAULT '{column.defaultString}'")

  let maxLength = column.info["maxLength"].getInt
  query.add(&" CHECK (length('{column.name}') <= {maxLength})")

  if column.isUnsigned:
    notAllowedOption("unsigned", "varchar", column.name)

  return @[query]


proc addTextColumn(table:Table, column:Column):seq[string] =
  var query = &"ALTER TABLE \"{table.name}\" ADD COLUMN '{column.name}' TEXT"

  if not column.isNullable:
    query.add(" NOT NULL")

  if column.isDefault:
    query.add(&" DEFAULT '{column.defaultString}'")

  if column.isUnsigned:
    notAllowedOption("unsigned", "text", column.name)

  return @[query]


# =============================================================================
# date
# =============================================================================
proc addDateColumn(table:Table, column:Column):seq[string] =
  var query = &"ALTER TABLE \"{table.name}\" ADD COLUMN '{column.name}' DATE"

  if not column.isNullable:
    query.add(" NOT NULL")

  if column.isDefault:
    query.add(&" DEFAULT CURRENT_TIMESTAMP")

  if column.isUnsigned:
    notAllowedOption("unsigned", "date", column.name)

  return @[query]


proc addDatetimeColumn(table:Table, column:Column):seq[string] =
  var query = &"ALTER TABLE \"{table.name}\" ADD COLUMN '{column.name}' DATETIME"

  if not column.isNullable:
    query.add(" NOT NULL")

  if column.isDefault:
    query.add(&" DEFAULT CURRENT_TIMESTAMP")

  if column.isUnsigned:
    notAllowedOption("unsigned", "datetime", column.name)

  return @[query]


proc addTimeColumn(table:Table, column:Column):seq[string] =
  var query = &"ALTER TABLE \"{table.name}\" ADD COLUMN '{column.name}' TIME"

  if not column.isNullable:
    query.add(" NOT NULL")

  if column.isDefault:
    query.add(&" DEFAULT CURRENT_TIMESTAMP")

  if column.isUnsigned:
    notAllowedOption("unsigned", "time", column.name)

  return @[query]


proc addTimestampColumn(table:Table, column:Column):seq[string] =
  var query = &"ALTER TABLE \"{table.name}\" ADD COLUMN '{column.name}' DATETIME"

  if not column.isNullable:
    query.add(" NOT NULL")

  if column.isDefault:
    query.add(&" DEFAULT CURRENT_TIMESTAMP")

  if column.isUnsigned:
    notAllowedOption("unsigned", "timestamp", column.name)

  return @[query]


proc addTimestampsColumn(table:Table, column:Column):seq[string] =
  result.add(&"ALTER TABLE \"{table.name}\" ADD COLUMN 'created_at' DATETIME DEFAULT CURRENT_TIMESTAMP")
  result.add(&"ALTER TABLE \"{table.name}\" ADD COLUMN 'updated_at' DATETIME DEFAULT CURRENT_TIMESTAMP")


proc addSoftDeleteColumn(table:Table, column:Column):seq[string] =
  return @[&"ALTER TABLE \"{table.name}\" ADD COLUMN 'deleted_at' DATETIME"]


# =============================================================================
# others
# =============================================================================
proc addBlobColumn(table:Table, column:Column):seq[string] =
  var query = &"ALTER TABLE \"{table.name}\" ADD COLUMN '{column.name}' BLOB"

  if not column.isNullable:
    query.add(" NOT NULL")

  if column.isDefault:
    query.add(&" DEFAULT '{column.defaultString}'")

  if column.isUnsigned:
    notAllowedOption("unsigned", "blob", column.name)

  return @[query]


proc addBoolColumn(table:Table, column:Column):seq[string] =
  var query = &"ALTER TABLE \"{table.name}\" ADD COLUMN '{column.name}' TINYINT"

  if not column.isNullable:
    query.add(" NOT NULL")

  if column.isDefault:
    query.add(&" DEFAULT {column.defaultBool}")

  if column.isUnsigned:
    notAllowedOption("unsigned", "bool", column.name)

  return @[query]


proc enumOptions(name:string, options:seq[string]):string =
  var optionsString = ""
  for i, option in options:
    if i > 0: optionsString.add(" OR ")
    optionsString.add(
      &"{name} = '{option}'"
    )

  return optionsString


proc addEnumColumn(table:Table, column:Column):seq[string] =
  var query = &"ALTER TABLE \"{table.name}\" ADD COLUMN '{column.name}' VARCHAR"

  if not column.isNullable:
    query.add(" NOT NULL")

  if column.isDefault:
    query.add(&" DEFAULT '{column.defaultString}'")

  var options:seq[string]
  for row in column.info["options"].items:
    options.add(row.getStr)

  let optionsString = enumOptions(column.name, options)
  query.add(&" CHECK ({optionsString})")

  if column.isUnsigned:
    notAllowedOption("unsigned", "enum", column.name)

  return @[query]


proc addJsonColumn(table:Table, column:Column):seq[string] =
  var query = &"ALTER TABLE \"{table.name}\" ADD COLUMN '{column.name}' JSON"

  if not column.isNullable:
    query.add(" NOT NULL")

  if column.isDefault:
    query.add(&" DEFAULT '{column.defaultJson.pretty}'")

  if column.isUnsigned:
    notAllowedOption("unsigned", "json", column.name)

  return @[query]


# =============================================================================
# foreign key
# =============================================================================
proc addForeignKey(column:Column):string =
  var onDeleteString = "RESTRICT"
  if column.foreignOnDelete == CASCADE:
    onDeleteString = "CASCADE"
  elif column.foreignOnDelete == SET_NULL:
    onDeleteString = "SET NULL"
  elif column.foreignOnDelete == NO_ACTION:
    onDeleteString = "NO ACTION"

  let tableName = column.info["table"].getStr
  let columnName = column.info["column"].getStr

  return &" REFERENCES \"{tableName}\"('{columnName}') ON DELETE {onDeleteString}"


proc addForeignColumn(table:Table, column:Column):seq[string] =
  var query = &"ALTER TABLE \"{table.name}\" ADD COLUMN '{column.name}' INTEGER"
  if column.isDefault:
    query.add(&" DEFAULT {column.defaultInt}")

  query.add(addForeignKey(column))

  return @[query]


proc addStrForeignColumn(table:Table, column:Column):seq[string] =
  var query = &"ALTER TABLE \"{table.name}\" ADD COLUMN '{column.name}' VARCHAR"
  if column.isDefault:
    query.add(&" DEFAULT {column.defaultString}")

  query.add(addForeignKey(column))

  return @[query]


proc addUniqueColumn(column:Column, table:Table):string =
  return &"CREATE UNIQUE INDEX IF NOT EXISTS \"{table.name}_{column.name}_unique\" ON \"{table.name}\"('{column.name}')"


proc addIndexColumn(column:Column, table:Table):string =
  return &"CREATE INDEX IF NOT EXISTS \"{table.name}_{column.name}_index\" ON \"{table.name}\"('{column.name}')"


proc addColumnString*(rdb:SqliteConnections, table:Table, column:Column):seq[string] =
  var queries:seq[string]
  case column.typ
  of rdbIncrements:
    let query = createColumnString(column)
    queries.add(addSerialColumn(rdb, table, column, query))
  of rdbInteger:
    queries.add(addIntColumn(table, column))
  of rdbSmallInteger:
    queries.add(addIntColumn(table, column))
  of rdbMediumInteger:
    queries.add(addIntColumn(table, column))
  of rdbBigInteger:
    queries.add(addIntColumn(table, column))
    # float
  of rdbDecimal:
    queries.add(addDecimalColumn(table, column))
  of rdbDouble:
    queries.add(addDecimalColumn(table, column))
  of rdbFloat:
    queries.add(addFloatColumn(table, column))
    # char
  of rdbUuid:
    queries.add(addUuidColumn(table, column))
  of rdbChar:
    queries.add(addCharColumn(table, column))
  of rdbString:
    queries.add(addVarcharColumn(table, column))
    # text
  of rdbText:
    queries.add(addTextColumn(table, column))
  of rdbMediumText:
    queries.add(addTextColumn(table, column))
  of rdbLongText:
    queries.add(addTextColumn(table, column))
    # date
  of rdbDate:
    queries.add(addDateColumn(table, column))
  of rdbDatetime:
    queries.add(addDatetimeColumn(table, column))
  of rdbTime:
    queries.add(addTimeColumn(table, column))
  of rdbTimestamp:
    queries.add(addTimestampColumn(table, column))
  of rdbTimestamps:
    queries.add(addTimestampsColumn(table, column))
  of rdbSoftDelete:
    queries.add(addSoftDeleteColumn(table, column))
    # others
  of rdbBinary:
    queries.add(addBlobColumn(table, column))
  of rdbBoolean:
    queries.add(addBoolColumn(table, column))
  of rdbEnumField:
    queries.add(addEnumColumn(table, column))
  of rdbJson:
    queries.add(addJsonColumn(table, column))
  # foreign
  of rdbForeign:
    queries.add(addForeignColumn(table, column))
  of rdbStrForeign:
    queries.add(addStrForeignColumn(table, column))

  let indexQuery = 
    if column.isUnique:
      column.addUniqueColumn(table)
    elif column.isIndex:
      column.addIndexColumn(table)
    else:
      ""

  if indexQuery.len > 0:
    queries.add(indexQuery)

  return queries
