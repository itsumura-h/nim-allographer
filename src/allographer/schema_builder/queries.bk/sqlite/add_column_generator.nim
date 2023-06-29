## https://www.sqlite.org/lang_createtable.html#constraints

import std/asyncdispatch
import std/json
import std/strformat
import std/strutils
import std/re
import ../../../query_builder/rdb/rdb_types
import ../../../query_builder/rdb/rdb_interface
import ../../../query_builder/rdb/query/grammar
import ../../enums
import ../../models/table
import ../../models/column
import ../query_util


# =============================================================================
# int
# =============================================================================
proc addSerialColumn*(rdb:Rdb, table:Table, column:Column):seq[string] =
  # get culumn definition
  let tableDifinitionSql = &"SELECT sql FROM sqlite_master WHERE type = 'table' AND name = '{table.name}'"
  var rows = rdb.raw(tableDifinitionSql).get.waitFor
  let schema = replace(rows[0]["sql"].getStr, re"\)$", ",)")
  var query = schema.replace(re",\)", &", {column.query},)")
  query = query.replace(re",\)", ")")
  query = query.replace(re("CREATE TABLE \".+\""), "CREATE TABLE \"alter_table_tmp\"")
  result.add(query)
  # copy data from existing table to tmp table
  var columns = rdb.table(table.name).columns().waitFor
  for i, row in columns:
    columns[i] = &"'{row}'"
  let columnsString = columns.join(", ")
  query = &"INSERT INTO \"alter_table_tmp\"({columnsString}) SELECT {columnsString} FROM \"{table.name}\""
  result.add(query)
  # delete existing table
  query = &"DROP TABLE IF EXISTS \"{table.name}\""
  result.add(query)
  # rename tmp table to existing table
  query = &"ALTER TABLE \"alter_table_tmp\" RENAME TO \"{table.name}\""
  result.add(query)


proc addIntColumn*(table:Table, column:Column):seq[string] =
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
proc addDecimalColumn*(table:Table, column:Column):seq[string] =
  var query = &"ALTER TABLE \"{table.name}\" ADD COLUMN '{column.name}' NUMERIC"

  if not column.isNullable:
    query.add(" NOT NULL")

  if column.isDefault:
    query.add(&" DEFAULT {column.defaultFloat}")

  if column.isUnsigned:
    query.add(&" CHECK ({column.name} >= 0)")

  return @[query]


proc addFloatColumn*(table:Table, column:Column):seq[string] =
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
proc addUuidColumn*(table:Table, column:Column):seq[string] =
  var query = &"ALTER TABLE \"{table.name}\" ADD COLUMN '{column.name}' VARCHAR"

  if not column.isNullable:
    query.add(" NOT NULL")

  if column.isDefault:
    query.add(&" DEFAULT '{column.defaultString}'")

  let maxLength = column.info["maxLength"].getInt
  query.add(&" CHECK (length('{column.name}') <= {maxLength})")

  if column.isUnsigned:
    notAllowed("unsigned", "varchar", column.name)

  return @[query]


proc addCharColumn*(table:Table, column:Column):seq[string] =
  var query = &"ALTER TABLE \"{table.name}\" ADD COLUMN '{column.name}' VARCHAR"

  if not column.isNullable:
    query.add(" NOT NULL")

  if column.isDefault:
    query.add(&" DEFAULT '{column.defaultString}'")

  let maxLength = column.info["maxLength"].getInt
  query.add(&" CHECK (length('{column.name}') <= {maxLength})")

  if column.isUnsigned:
    notAllowed("unsigned", "char", column.name)

  return @[query]


proc addVarcharColumn*(table:Table, column:Column):seq[string] =
  var query = &"ALTER TABLE \"{table.name}\" ADD COLUMN '{column.name}' VARCHAR"

  if not column.isNullable:
    query.add(" NOT NULL")

  if column.isDefault:
    query.add(&" DEFAULT '{column.defaultString}'")

  let maxLength = column.info["maxLength"].getInt
  query.add(&" CHECK (length('{column.name}') <= {maxLength})")

  if column.isUnsigned:
    notAllowed("unsigned", "varchar", column.name)

  return @[query]


proc addTextColumn*(table:Table, column:Column):seq[string] =
  var query = &"ALTER TABLE \"{table.name}\" ADD COLUMN '{column.name}' TEXT"

  if not column.isNullable:
    query.add(" NOT NULL")

  if column.isDefault:
    query.add(&" DEFAULT '{column.defaultString}'")

  if column.isUnsigned:
    notAllowed("unsigned", "text", column.name)

  return @[query]


# =============================================================================
# date
# =============================================================================
proc addDateColumn*(table:Table, column:Column):seq[string] =
  var query = &"ALTER TABLE \"{table.name}\" ADD COLUMN '{column.name}' DATE"

  if not column.isNullable:
    query.add(" NOT NULL")

  if column.isDefault:
    query.add(&" DEFAULT CURRENT_TIMESTAMP")

  if column.isUnsigned:
    notAllowed("unsigned", "date", column.name)

  return @[query]


proc addDatetimeColumn*(table:Table, column:Column):seq[string] =
  var query = &"ALTER TABLE \"{table.name}\" ADD COLUMN '{column.name}' DATETIME"

  if not column.isNullable:
    query.add(" NOT NULL")

  if column.isDefault:
    query.add(&" DEFAULT CURRENT_TIMESTAMP")

  if column.isUnsigned:
    notAllowed("unsigned", "datetime", column.name)

  return @[query]


proc addTimeColumn*(table:Table, column:Column):seq[string] =
  var query = &"ALTER TABLE \"{table.name}\" ADD COLUMN '{column.name}' TIME"

  if not column.isNullable:
    query.add(" NOT NULL")

  if column.isDefault:
    query.add(&" DEFAULT CURRENT_TIMESTAMP")

  if column.isUnsigned:
    notAllowed("unsigned", "time", column.name)

  return @[query]


proc addTimestampColumn*(table:Table, column:Column):seq[string] =
  var query = &"ALTER TABLE \"{table.name}\" ADD COLUMN '{column.name}' DATETIME"

  if not column.isNullable:
    query.add(" NOT NULL")

  if column.isDefault:
    query.add(&" DEFAULT CURRENT_TIMESTAMP")

  if column.isUnsigned:
    notAllowed("unsigned", "timestamp", column.name)

  return @[query]


proc addTimestampsColumn*(table:Table, column:Column):seq[string] =
  result.add(&"ALTER TABLE \"{table.name}\" ADD COLUMN 'created_at' DATETIME DEFAULT CURRENT_TIMESTAMP")
  result.add(&"ALTER TABLE \"{table.name}\" ADD COLUMN 'updated_at' DATETIME DEFAULT CURRENT_TIMESTAMP")


proc addSoftDeleteColumn*(table:Table, column:Column):seq[string] =
  return @[&"ALTER TABLE \"{table.name}\" ADD COLUMN 'deleted_at' DATETIME"]


# =============================================================================
# others
# =============================================================================
proc addBlobColumn*(table:Table, column:Column):seq[string] =
  var query = &"ALTER TABLE \"{table.name}\" ADD COLUMN '{column.name}' BLOB"

  if not column.isNullable:
    query.add(" NOT NULL")

  if column.isDefault:
    query.add(&" DEFAULT '{column.defaultString}'")

  if column.isUnsigned:
    notAllowed("unsigned", "blob", column.name)

  return @[query]


proc addBoolColumn*(table:Table, column:Column):seq[string] =
  var query = &"ALTER TABLE \"{table.name}\" ADD COLUMN '{column.name}' TINYINT"

  if not column.isNullable:
    query.add(" NOT NULL")

  if column.isDefault:
    query.add(&" DEFAULT {column.defaultBool}")

  if column.isUnsigned:
    notAllowed("unsigned", "bool", column.name)

  return @[query]


proc enumOptions(name:string, options:seq[string]):string =
  var optionsString = ""
  for i, option in options:
    if i > 0: optionsString.add(" OR ")
    optionsString.add(
      &"{name} = '{option}'"
    )

  return optionsString


proc addEnumColumn*(table:Table, column:Column):seq[string] =
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
    notAllowed("unsigned", "enum", column.name)

  return @[query]


proc addJsonColumn*(table:Table, column:Column):seq[string] =
  var query = &"ALTER TABLE \"{table.name}\" ADD COLUMN '{column.name}' TEXT"

  if not column.isNullable:
    query.add(" NOT NULL")

  if column.isDefault:
    query.add(&" DEFAULT '{column.defaultJson.pretty}'")

  if column.isUnsigned:
    notAllowed("unsigned", "json", column.name)

  return @[query]


# =============================================================================
# foreign key
# =============================================================================
proc addForeignColumn*(table:Table, column:Column):seq[string] =
  var query = &"ALTER TABLE \"{table.name}\" ADD COLUMN '{column.name}' INTEGER"
  if column.isDefault:
    query.add(&" DEFAULT {column.defaultInt}")

  return @[query]


proc addStrForeignColumn*(table:Table, column:Column):seq[string] =
  var query = &"ALTER TABLE \"{table.name}\" ADD COLUMN '{column.name}' VARCHAR"
  if column.isDefault:
    query.add(&" DEFAULT {column.defaultString}")

  return @[query]


proc addForeignKey*(table:Table, column:Column):seq[string] =
  var onDeleteString = "RESTRICT"
  if column.foreignOnDelete == CASCADE:
    onDeleteString = "CASCADE"
  elif column.foreignOnDelete == SET_NULL:
    onDeleteString = "SET NULL"
  elif column.foreignOnDelete == NO_ACTION:
    onDeleteString = "NO ACTION"

  return @[&"ALTER TABLE \"{table.name}\" ADD COLUMN '{column.name}' INTEGER REFERENCES \"{table.name}\"('{column.name}') ON DELETE {onDeleteString}"]


proc addUniqueColumn*(column:Column, table:Table):string =
  let table = table.name
  let smallTable = table.toLowerAscii()
  return &"CREATE UNIQUE INDEX IF NOT EXISTS \"{smallTable}_{column.name}_unique\" ON \"{table}\"('{column.name}')"


proc addIndexColumn*(column:Column, table:Table):string =
  let table = table.name
  let smallTable = table.toLowerAscii()
  return &"CREATE INDEX IF NOT EXISTS \"{smallTable}_{column.name}_index\" ON \"{table}\"('{column.name}')"
