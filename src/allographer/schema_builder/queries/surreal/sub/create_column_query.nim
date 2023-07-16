## https://surrealdb.com/docs/surrealql/statements/define/field
## https://surrealdb.com/docs/surrealql/statements/define/indexes
## https://surrealdb.com/docs/surrealql/datamodel/ids
## https://surrealdb.com/docs/surrealql/datamodel/simple
## https://surrealdb.com/docs/surrealql/datamodel/numbers
## https://surrealdb.com/docs/surrealql/datamodel/strings

import std/json
import std/strformat
import std/strutils
import ../../../enums
import ../../../models/table
import ../../../models/column
import ../../query_utils


# =============================================================================
# int
# =============================================================================
proc createIncrementsColumn(column:Column, table:Table):seq[string] =
  result.add(&"DEFINE FIELD `{column.name}` ON TABLE `{table.name}` TYPE int VALUE (SELECT `{column.name}` FROM `{table.name}` ORDER BY `{column.name}` NUMERIC DESC LIMIT 1)[0].{column.name} + 1 || 1 ASSERT $value != NONE")
  result.add(&"DEFINE INDEX `{table.name}_{column.name}_unique` ON TABLE `{table.name}` COLUMNS `{column.name}` UNIQUE")

proc createIntColumn(column:Column, table:Table):seq[string] =
  var query = &"DEFINE FIELD `{column.name}` ON TABLE `{table.name}` TYPE int"

  if not column.isNullable:
    query.add(" ASSERT $value != NONE")

  if column.isUnsigned:
    if query.contains("ASSERT"):
      query.add(&" AND $value >= 0")
    else:
      query.add(&" ASSERT $value >= 0")

  if column.isDefault:
    query.add(&" VALUE $value OR {column.defaultInt}")

  if column.isAutoIncrement:
    query.add(&" VALUE (SELECT `{column.name}` FROM `{table.name}` ORDER BY `{column.name}` NUMERIC DESC LIMIT 1)[0].{column.name} + 1 || 1")

  result.add(query)

  if column.isIndex:
    result.add(&"DEFINE INDEX `{table.name}_{column.name}_index` ON TABLE `{table.name}` COLUMNS `{column.name}`")

  if column.isUnique:
    result.add(&"DEFINE INDEX `{table.name}_{column.name}_unique` ON TABLE `{table.name}` COLUMNS `{column.name}` UNIQUE")


# =============================================================================
# float
# =============================================================================
proc createDecimalColumn(column:Column, table:Table):seq[string] =
  var query = &"DEFINE FIELD `{column.name}` ON TABLE `{table.name}` TYPE decimal"

  if not column.isNullable:
    query.add(" ASSERT $value != NONE")

  if column.isUnsigned:
    if query.contains("ASSERT"):
      query.add(&" AND $value >= 0")
    else:
      query.add(&" ASSERT $value >= 0")

  if column.isDefault:
    query.add(&" VALUE $value OR {column.defaultFloat}")

  if column.isAutoIncrement:
    notAllowedOption("autoincrement", "decimal", column.name)

  result.add(query)

  if column.isIndex:
    result.add(&"DEFINE INDEX `{table.name}_{column.name}_index` ON TABLE `{table.name}` COLUMNS `{column.name}`")

  if column.isUnique:
    result.add(&"DEFINE INDEX `{table.name}_{column.name}_unique` ON TABLE `{table.name}` COLUMNS `{column.name}` UNIQUE")


proc createFloatColumn(column:Column, table:Table):seq[string] =
  var query = &"DEFINE FIELD `{column.name}` ON TABLE `{table.name}` TYPE float"

  if not column.isNullable:
    query.add(" ASSERT $value != NONE")

  if column.isUnsigned:
    if query.contains("ASSERT"):
      query.add(&" AND $value >= 0")
    else:
      query.add(&" ASSERT $value >= 0")

  if column.isDefault:
    query.add(&" VALUE $value OR {column.defaultFloat}")

  if column.isAutoIncrement:
    notAllowedOption("autoincrement", "decimal", column.name)

  result.add(query)

  if column.isIndex:
    result.add(&"DEFINE INDEX `{table.name}_{column.name}_index` ON TABLE `{table.name}` COLUMNS `{column.name}`")

  if column.isUnique:
    result.add(&"DEFINE INDEX `{table.name}_{column.name}_unique` ON TABLE `{table.name}` COLUMNS `{column.name}` UNIQUE")


# =============================================================================
# char
# =============================================================================
proc createUuidColumn(column:Column, table:Table):seq[string] =
  result.add(&"DEFINE FIELD `{column.name}` ON TABLE `{table.name}` TYPE string VALUE $value OR rand::uuid() ASSERT $value != NONE")
  result.add(&"DEFINE INDEX `{table.name}_{column.name}_unique` ON TABLE `{table.name}` COLUMNS `{column.name}` UNIQUE")


proc createCharColumn(column:Column, table:Table):seq[string] =
  var query = &"DEFINE FIELD `{column.name}` ON TABLE `{table.name}` TYPE string"

  let maxLength = column.info["maxLength"].getInt
  query.add(&" ASSERT string::len($value) < {maxLength}")

  if not column.isNullable:
    query.add(" AND $value != NONE")

  if column.isDefault:
    query.add(&" VALUE $value OR '{column.defaultString}'")
  
  if column.isAutoIncrement:
    notAllowedOption("autoincrement", "decimal", column.name)

  result.add(query)

  if column.isIndex:
    result.add(&"DEFINE INDEX `{table.name}_{column.name}_index` ON TABLE `{table.name}` COLUMNS `{column.name}`")

  if column.isUnique:
    result.add(&"DEFINE INDEX `{table.name}_{column.name}_unique` ON TABLE `{table.name}` COLUMNS `{column.name}` UNIQUE")

  if column.isUnsigned:
    notAllowedOption("unsigned", "varchar", column.name)


proc createVarcharColumn(column:Column, table:Table):seq[string] =
  var query = &"DEFINE FIELD `{column.name}` ON TABLE `{table.name}` TYPE string"

  let maxLength = column.info["maxLength"].getInt
  query.add(&" ASSERT string::len($value) < {maxLength}")

  if not column.isNullable:
    query.add(" AND $value != NONE")

  if column.isDefault:
    query.add(&" VALUE $value OR '{column.defaultString}'")

  if column.isAutoIncrement:
    notAllowedOption("autoincrement", "decimal", column.name)

  result.add(query)

  if column.isIndex:
    result.add(&"DEFINE INDEX `{table.name}_{column.name}_index` ON TABLE `{table.name}` COLUMNS `{column.name}`")

  if column.isUnique:
    result.add(&"DEFINE INDEX `{table.name}_{column.name}_unique` ON TABLE `{table.name}` COLUMNS `{column.name}` UNIQUE")

  if column.isUnsigned:
    notAllowedOption("unsigned", "varchar", column.name)


proc createTextColumn(column:Column, table:Table):seq[string] =
  var query = &"DEFINE FIELD `{column.name}` ON TABLE `{table.name}` TYPE string"

  if not column.isNullable:
    query.add(" ASSERT $value != NONE")

  if column.isDefault:
    query.add(&" VALUE $value OR '{column.defaultString}'")

  if column.isAutoIncrement:
    notAllowedOption("autoincrement", "decimal", column.name)

  result.add(query)

  if column.isIndex:
    result.add(&"DEFINE INDEX `{table.name}_{column.name}_index` ON TABLE `{table.name}` COLUMNS `{column.name}`")

  if column.isUnique:
    result.add(&"DEFINE INDEX `{table.name}_{column.name}_unique` ON TABLE `{table.name}` COLUMNS `{column.name}` UNIQUE")

  if column.isUnsigned:
    notAllowedOption("unsigned", "varchar", column.name)


# =============================================================================
# date
# =============================================================================
# proc createDateColumn(column:Column, table:Table):seq[string] =
#   var query = &"DEFINE FIELD `{column.name}` ON TABLE `{table.name}` TYPE string"

#   if not column.isNullable:
#     query.add(" ASSERT $value != NONE")

#   if column.isDefault:
#     query.add(&" VALUE $value OR '{column.defaultString}'")

#   result.add(query)

#   if column.isIndex:
#     result.add(&"DEFINE INDEX `{table.name}_{column.name}_index` ON TABLE `{table.name}` COLUMNS `{column.name}`")

#   if column.isUnique:
#     result.add(&"DEFINE INDEX `{table.name}_{column.name}_unique` ON TABLE `{table.name}` COLUMNS `{column.name}` UNIQUE")

#   if column.isUnsigned:
#     notAllowedOption("unsigned", "varchar", column.name)


proc createDatetimeColumn(column:Column, table:Table):seq[string] =
  var query = &"DEFINE FIELD `{column.name}` ON TABLE `{table.name}` TYPE datetime"

  if not column.isNullable:
    query.add(" ASSERT $value != NONE")

  if column.isDefault:
    query.add(&" VALUE $value OR time::now()")

  if column.isAutoIncrement:
    notAllowedOption("autoincrement", "decimal", column.name)

  result.add(query)

  if column.isIndex:
    result.add(&"DEFINE INDEX `{table.name}_{column.name}_index` ON TABLE `{table.name}` COLUMNS `{column.name}`")

  if column.isUnique:
    result.add(&"DEFINE INDEX `{table.name}_{column.name}_unique` ON TABLE `{table.name}` COLUMNS `{column.name}` UNIQUE")

  if column.isUnsigned:
    notAllowedOption("unsigned", "varchar", column.name)


# proc createTimeColumn(column:Column, table:Table):seq[string] =
#   var query = &"DEFINE FIELD `{column.name}` ON TABLE `{table.name}` TYPE string"

#   if not column.isNullable:
#     query.add(" ASSERT $value != NONE")

#   if column.isDefault:
#     query.add(&" VALUE $value OR '{column.defaultString}'")

#   result.add(query)

#   if column.isIndex:
#     result.add(&"DEFINE INDEX `{table.name}_{column.name}_index` ON TABLE `{table.name}` COLUMNS `{column.name}`")

#   if column.isUnique:
#     result.add(&"DEFINE INDEX `{table.name}_{column.name}_unique` ON TABLE `{table.name}` COLUMNS `{column.name}` UNIQUE")

#   if column.isUnsigned:
#     notAllowedOption("unsigned", "varchar", column.name)


# proc createTimestampColumn(column:Column, table:Table):seq[string] =
#   var query = &"DEFINE FIELD `{column.name}` ON TABLE `{table.name}` TYPE string"

#   if not column.isNullable:
#     query.add(" ASSERT $value != NONE")

#   if column.isDefault:
#     query.add(&" VALUE $value OR '{column.defaultString}'")

#   result.add(query)

#   if column.isIndex:
#     result.add(&"DEFINE INDEX `{table.name}_{column.name}_index` ON TABLE `{table.name}` COLUMNS `{column.name}`")

#   if column.isUnique:
#     result.add(&"DEFINE INDEX `{table.name}_{column.name}_unique` ON TABLE `{table.name}` COLUMNS `{column.name}` UNIQUE")

#   if column.isUnsigned:
#     notAllowedOption("unsigned", "varchar", column.name)


proc createTimestampsColumn(column:Column, table:Table):seq[string] =
  result.add(&"DEFINE FIELD `created_at` ON TABLE `{table.name}` TYPE datetime VALUE time::now()")
  result.add(&"DEFINE INDEX `{table.name}_created_at_index` ON TABLE `{table.name}` COLUMNS `created_at`")

  result.add(&"DEFINE FIELD `updated_at` ON TABLE `{table.name}` TYPE datetime VALUE time::now()")
  result.add(&"DEFINE INDEX `{table.name}_updated_at_index` ON TABLE `{table.name}` COLUMNS `updated_at`")


proc createSoftDeleteColumn(column:Column, table:Table):seq[string] =
  result.add(&"DEFINE FIELD `deleted_at` ON TABLE `{table.name}` TYPE datetime")
  result.add(&"DEFINE INDEX `{table.name}_deleted_at_index` ON TABLE `{table.name}` COLUMNS `deleted_at`")


# =============================================================================
# others
# =============================================================================
proc createBlobColumn(column:Column, table:Table):seq[string] =
  var query = &"DEFINE FIELD `{column.name}` ON TABLE `{table.name}` TYPE string"

  if not column.isNullable:
    query.add(" ASSERT $value != NONE")

  if column.isDefault:
    query.add(&" VALUE $value OR '{column.defaultString}'")

  if column.isAutoIncrement:
    notAllowedOption("autoincrement", "decimal", column.name)

  result.add(query)

  if column.isIndex:
    result.add(&"DEFINE INDEX `{table.name}_{column.name}_index` ON TABLE `{table.name}` COLUMNS `{column.name}`")

  if column.isUnique:
    result.add(&"DEFINE INDEX `{table.name}_{column.name}_unique` ON TABLE `{table.name}` COLUMNS `{column.name}` UNIQUE")

  if column.isUnsigned:
    notAllowedOption("unsigned", "blob", column.name)


proc createBoolColumn(column:Column, table:Table):seq[string] =
  var query = &"DEFINE FIELD `{column.name}` ON TABLE `{table.name}` TYPE bool"

  if not column.isNullable:
    query.add(" ASSERT $value != NONE")

  if column.isDefault:
    query.add(&" VALUE $value OR {column.defaultBool}")

  if column.isAutoIncrement:
    notAllowedOption("autoincrement", "decimal", column.name)

  result.add(query)

  if column.isIndex:
    result.add(&"DEFINE INDEX `{table.name}_{column.name}_index` ON TABLE `{table.name}` COLUMNS `{column.name}`")

  if column.isUnique:
    result.add(&"DEFINE INDEX `{table.name}_{column.name}_unique` ON TABLE `{table.name}` COLUMNS `{column.name}` UNIQUE")

  if column.isUnsigned:
    notAllowedOption("unsigned", "bool", column.name)


proc enumOptionsColumn(options:seq[string]):string =
  var optionsString = ""
  for i, option in options:
    if i > 0: optionsString.add(", ")
    optionsString.add(
      &"'{option}'"
    )

  return optionsString


proc createEnumColumn(column:Column, table:Table):seq[string] =
  var query = &"DEFINE FIELD `{column.name}` ON TABLE `{table.name}` TYPE string"
  
  var options:seq[string]
  for row in column.info["options"].items:
    options.add(row.getStr)
  let optionsString = enumOptionsColumn(options)
  query.add(&" ASSERT $value INSIDE [{optionsString}]")

  if not column.isNullable:
    query.add(" AND $value != NONE")

  if column.isDefault:
    query.add(&" VALUE $value OR '{column.defaultString}'")

  if column.isAutoIncrement:
    notAllowedOption("autoincrement", "decimal", column.name)

  result.add(query)

  if column.isIndex:
    result.add(&"DEFINE INDEX `{table.name}_{column.name}_index` ON TABLE `{table.name}` COLUMNS `{column.name}`")

  if column.isUnique:
    result.add(&"DEFINE INDEX `{table.name}_{column.name}_unique` ON TABLE `{table.name}` COLUMNS `{column.name}` UNIQUE")

  if column.isUnsigned:
    notAllowedOption("unsigned", "enum", column.name)


proc createJsonColumn(column:Column, table:Table):seq[string] =
  var query = &"DEFINE FIELD `{column.name}` ON TABLE `{table.name}` FLEXIBLE TYPE object"

  if not column.isNullable:
    query.add(" ASSERT $value != NONE")

  if column.isDefault:
    query.add(&" VALUE $value OR {$column.defaultJson}")

  if column.isAutoIncrement:
    notAllowedOption("autoincrement", "decimal", column.name)

  result.add(query)

  if column.isIndex:
    result.add(&"DEFINE INDEX `{table.name}_{column.name}_index` ON TABLE `{table.name}` COLUMNS `{column.name}`")

  if column.isUnique:
    result.add(&"DEFINE INDEX `{table.name}_{column.name}_unique` ON TABLE `{table.name}` COLUMNS `{column.name}` UNIQUE")

  if column.isUnsigned:
    notAllowedOption("unsigned", "json", column.name)


# =============================================================================
# foreign key
# =============================================================================
proc createForeignColumn(column:Column, table:Table):seq[string] =
  let refTable = column.info["table"].getStr
  var query = &"DEFINE FIELD `{column.name}` ON TABLE `{table.name}` TYPE record (`{refTable}`)"

  if not column.isNullable:
    query.add(" ASSERT $value != NONE")

  if column.isDefault:
    query.add(&" VALUE $value OR {$column.defaultString}")

  if column.isAutoIncrement:
    notAllowedOption("autoincrement", "decimal", column.name)

  result.add(query)

  if column.isIndex:
    result.add(&"DEFINE INDEX `{table.name}_{column.name}_index` ON TABLE `{table.name}` COLUMNS `{column.name}`")

  if column.isUnique:
    result.add(&"DEFINE INDEX `{table.name}_{column.name}_unique` ON TABLE `{table.name}` COLUMNS `{column.name}` UNIQUE")

  if column.isUnsigned:
    notAllowedOption("unsigned", "foreign", column.name)


# proc createStrForeignColumn(column:Column, table:Table):string =
#   result = &"'{column.name}' VARCHAR"
#   if column.isDefault:
#     result.add(&" DEFAULT {column.defaultString}")


# proc createForeignKey(column:Column):string =
#   var onDeleteString = "RESTRICT"
#   if column.foreignOnDelete == CASCADE:
#     onDeleteString = "CASCADE"
#   elif column.foreignOnDelete == SET_NULL:
#     onDeleteString = "SET NULL"
#   elif column.foreignOnDelete == NO_ACTION:
#     onDeleteString = "NO ACTION"

#   let tableName = column.info["table"].getStr
#   let columnnName = column.info["column"].getStr
#   return &"FOREIGN KEY('{column.name}') REFERENCES \"{tableName}\"('{columnnName}') ON DELETE {onDeleteString}"


# proc createIndexColumn(column:Column, table:Table):string =
#   return &"CREATE INDEX IF NOT EXISTS \"{table.name}_{column.name}_index\" ON \"{table.name}\"('{column.name}')"


proc createColumnString*(table:Table, column:Column):seq[string] =
  case column.typ:
    # int
  of rdbIncrements:
    return column.createIncrementsColumn(table)
  of rdbInteger:
    return column.createIntColumn(table)
  of rdbSmallInteger:
    return column.createIntColumn(table)
  of rdbMediumInteger:
    return column.createIntColumn(table)
  of rdbBigInteger:
    return column.createIntColumn(table)
    # float
  of rdbDecimal:
    return column.createDecimalColumn(table)
  of rdbDouble:
    return column.createDecimalColumn(table)
  of rdbFloat:
    return column.createFloatColumn(table)
    # char
  of rdbUuid:
    return column.createUuidColumn(table)
  of rdbChar:
    return column.createCharColumn(table)
  of rdbString:
    return column.createVarcharColumn(table)
    # text
  of rdbText:
    return column.createTextColumn(table)
  of rdbMediumText:
    return column.createTextColumn(table)
  of rdbLongText:
    return column.createTextColumn(table)
    # date
  of rdbDate:
    return column.createDatetimeColumn(table)
  of rdbDatetime:
    return column.createDatetimeColumn(table)
  of rdbTime:
    notAllowedType("time")
    # return column.createDatetimeColumn(table)
  of rdbTimestamp:
    return column.createDatetimeColumn(table)
  of rdbTimestamps:
    return column.createTimestampsColumn(table)
  of rdbSoftDelete:
    return column.createSoftDeleteColumn(table)
  #   # others
  of rdbBinary:
    return column.createBlobColumn(table)
  of rdbBoolean:
    return column.createBoolColumn(table)
  of rdbEnumField:
    return column.createEnumColumn(table)
  of rdbJson:
    return column.createJsonColumn(table)
  # foreign
  of rdbForeign:
    return column.createForeignColumn(table)
  of rdbStrForeign:
    return column.createForeignColumn(table)
  # else:
  #   discard


# proc createForeignString*(column:Column):string =
#   # if column.typ == rdbForeign or column.typ == rdbStrForeign:
#   return column.createForeignKey()


# proc createIndexString*(table:Table, column:Column):string =
#   # if column.isIndex:
#   return column.createIndexColumn(table)
