## https://surrealdb.com/docs/surrealql/statements/define/field
## https://surrealdb.com/docs/surrealql/statements/define/indexes
## https://surrealdb.com/docs/surrealql/datamodel/ids
## https://surrealdb.com/docs/surrealql/datamodel/simple
## https://surrealdb.com/docs/surrealql/datamodel/numbers
## https://surrealdb.com/docs/surrealql/datamodel/strings

import std/json
import std/strformat
import ../../../enums
import ../../../models/table
import ../../../models/column
import ../schema_utils


proc addAssertPart(assertClause: var string, part: string) =
  if part.len == 0:
    return

  if assertClause.len > 0:
    assertClause.add(" AND ")
  assertClause.add(part)


proc addValueClause(query: var string, defaultClause: string, isNullable: bool, fallbackClause: string) =
  if defaultClause.len > 0:
    query.add(&" VALUE $value OR {defaultClause}")
  elif isNullable:
    query.add(" VALUE $value OR NONE")
  else:
    query.add(&" VALUE $value OR {fallbackClause}")


proc addAssertClause(query: var string, assertBody: string, isNullable: bool) =
  if assertBody.len == 0:
    if not isNullable:
      query.add(" ASSERT $value != NONE")
    return

  if isNullable:
    query.add(&" ASSERT $value = NONE OR ({assertBody})")
  else:
    query.add(&" ASSERT {assertBody}")


proc autoIncrementValueExpr(table: Table, column: Column): string =
  &"(SELECT `max_index` FROM `_autoincrement_sequences` WHERE `table` = \"{table.name}\" AND `column` = \"{column.name}\" LIMIT 1)[0].max_index + 1"


proc isSurrealIdField(column: Column): bool =
  column.name == "id"


# =============================================================================
# int
# =============================================================================
proc createIncrementsColumn(column:Column, table:Table):seq[string] =
  if isSurrealIdField(column):
    return @[]

  let nextIndexExpr = autoIncrementValueExpr(table, column)
  result.add(&"""
    INSERT INTO `_autoincrement_sequences` {{table: "{table.name}", column: "{column.name}", max_index: 0}};
    DEFINE EVENT `autoincrement_{table.name}_{column.name}` ON TABLE `{table.name}` WHEN $event = "CREATE" THEN {{
      UPDATE `_autoincrement_sequences` MERGE {{max_index: $after.{column.name}}} WHERE `table` = "{table.name}" AND `column` = "{column.name}";
    }}
  """)
  result.add(&"DEFINE FIELD `{column.name}` ON TABLE `{table.name}` TYPE int VALUE $value OR {nextIndexExpr}")
  result.add(&"DEFINE INDEX `{table.name}_{column.name}_unique` ON TABLE `{table.name}` COLUMNS `{column.name}` UNIQUE")


proc createIntColumn(column:Column, table:Table):seq[string] =
  var query = ""
  var assertClause = ""

  if column.isAutoIncrement:
    if isSurrealIdField(column):
      return @[]

    let nextIndexExpr = autoIncrementValueExpr(table, column)
    query.add(&"""
      INSERT INTO `_autoincrement_sequences` {{table: "{table.name}", column: "{column.name}", max_index: 0}};
      DEFINE EVENT `autoincrement_{table.name}_{column.name}` ON TABLE `{table.name}` WHEN $event = "CREATE" THEN {{
        UPDATE `_autoincrement_sequences` MERGE {{max_index: $after.{column.name}}} WHERE `table` = "{table.name}" AND `column` = "{column.name}";
      }};
    """)

    query.add(&"DEFINE FIELD `{column.name}` ON TABLE `{table.name}` TYPE int VALUE $value OR {nextIndexExpr}")
    return @[query]

  query.add(&"DEFINE FIELD `{column.name}` ON TABLE `{table.name}` TYPE int")
  if column.isNullable:
    query.add(" | NONE")

  if not column.isNullable:
    addAssertPart(assertClause, "$value != NONE")

  if column.isUnsigned:
    addAssertPart(assertClause, "$value >= 0")

  if column.isDefault:
    addValueClause(query, $column.defaultInt, column.isNullable, "0")
  else:
    addValueClause(query, "", column.isNullable, "0")

  addAssertClause(query, assertClause, column.isNullable)
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
  var assertClause = ""
  if column.isNullable:
    query.add(" | NONE")

  if not column.isNullable:
    addAssertPart(assertClause, "$value != NONE")

  if column.isUnsigned:
    addAssertPart(assertClause, "$value >= 0")

  if column.isDefault:
    addValueClause(query, $column.defaultFloat, column.isNullable, "0.0")
  else:
    addValueClause(query, "", column.isNullable, "0.0")

  if column.isAutoIncrement:
    notAllowedOption("autoincrement", "decimal", column.name)

  addAssertClause(query, assertClause, column.isNullable)
  result.add(query)

  if column.isIndex:
    result.add(&"DEFINE INDEX `{table.name}_{column.name}_index` ON TABLE `{table.name}` COLUMNS `{column.name}`")

  if column.isUnique:
    result.add(&"DEFINE INDEX `{table.name}_{column.name}_unique` ON TABLE `{table.name}` COLUMNS `{column.name}` UNIQUE")


proc createFloatColumn(column:Column, table:Table):seq[string] =
  var query = &"DEFINE FIELD `{column.name}` ON TABLE `{table.name}` TYPE float"
  var assertClause = ""
  if column.isNullable:
    query.add(" | NONE")

  if not column.isNullable:
    addAssertPart(assertClause, "$value != NONE")

  if column.isUnsigned:
    addAssertPart(assertClause, "$value >= 0")

  if column.isDefault:
    addValueClause(query, $column.defaultFloat, column.isNullable, "0.0")
  else:
    addValueClause(query, "", column.isNullable, "0.0")

  if column.isAutoIncrement:
    notAllowedOption("autoincrement", "decimal", column.name)

  addAssertClause(query, assertClause, column.isNullable)
  result.add(query)

  if column.isIndex:
    result.add(&"DEFINE INDEX `{table.name}_{column.name}_index` ON TABLE `{table.name}` COLUMNS `{column.name}`")

  if column.isUnique:
    result.add(&"DEFINE INDEX `{table.name}_{column.name}_unique` ON TABLE `{table.name}` COLUMNS `{column.name}` UNIQUE")


# =============================================================================
# char
# =============================================================================
proc createUuidColumn(column:Column, table:Table):seq[string] =
  var query = &"DEFINE FIELD `{column.name}` ON TABLE `{table.name}` TYPE string"
  if column.isNullable:
    query.add(" | NONE")
  query.add(" VALUE $value OR rand::uuid()")
  addAssertClause(query, "", column.isNullable)
  result.add(query)
  result.add(&"DEFINE INDEX `{table.name}_{column.name}_unique` ON TABLE `{table.name}` COLUMNS `{column.name}` UNIQUE")


proc createCharColumn(column:Column, table:Table):seq[string] =
  var query = &"DEFINE FIELD `{column.name}` ON TABLE `{table.name}` TYPE string"
  if column.isNullable:
    query.add(" | NONE")
  let maxLength = column.info["maxLength"].getInt
  var assertClause = &"string::len($value) < {maxLength}"

  if not column.isNullable:
    addAssertPart(assertClause, "$value != NONE")

  if column.isDefault:
    addValueClause(query, &"'{column.defaultString}'", column.isNullable, "''")
  else:
    addValueClause(query, "", column.isNullable, "''")

  if column.isAutoIncrement:
    notAllowedOption("autoincrement", "decimal", column.name)

  addAssertClause(query, assertClause, column.isNullable)
  result.add(query)

  if column.isIndex:
    result.add(&"DEFINE INDEX `{table.name}_{column.name}_index` ON TABLE `{table.name}` COLUMNS `{column.name}`")

  if column.isUnique:
    result.add(&"DEFINE INDEX `{table.name}_{column.name}_unique` ON TABLE `{table.name}` COLUMNS `{column.name}` UNIQUE")

  if column.isUnsigned:
    notAllowedOption("unsigned", "varchar", column.name)


proc createVarcharColumn(column:Column, table:Table):seq[string] =
  var query = &"DEFINE FIELD `{column.name}` ON TABLE `{table.name}` TYPE string"
  if column.isNullable:
    query.add(" | NONE")
  let maxLength = column.info["maxLength"].getInt
  var assertClause = &"string::len($value) < {maxLength}"

  if not column.isNullable:
    addAssertPart(assertClause, "$value != NONE")

  if column.isDefault:
    addValueClause(query, &"'{column.defaultString}'", column.isNullable, "''")
  else:
    addValueClause(query, "", column.isNullable, "''")

  if column.isAutoIncrement:
    notAllowedOption("autoincrement", "decimal", column.name)

  addAssertClause(query, assertClause, column.isNullable)
  result.add(query)

  if column.isIndex:
    result.add(&"DEFINE INDEX `{table.name}_{column.name}_index` ON TABLE `{table.name}` COLUMNS `{column.name}`")

  if column.isUnique:
    result.add(&"DEFINE INDEX `{table.name}_{column.name}_unique` ON TABLE `{table.name}` COLUMNS `{column.name}` UNIQUE")

  if column.isUnsigned:
    notAllowedOption("unsigned", "varchar", column.name)


proc createTextColumn(column:Column, table:Table):seq[string] =
  var query = &"DEFINE FIELD `{column.name}` ON TABLE `{table.name}` TYPE string"
  var assertClause = ""
  if column.isNullable:
    query.add(" | NONE")

  if not column.isNullable:
    addAssertPart(assertClause, "$value != NONE")

  if column.isDefault:
    addValueClause(query, &"'{column.defaultString}'", column.isNullable, "''")
  else:
    addValueClause(query, "", column.isNullable, "''")

  if column.isAutoIncrement:
    notAllowedOption("autoincrement", "decimal", column.name)

  addAssertClause(query, assertClause, column.isNullable)
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
proc createDatetimeColumn(column:Column, table:Table):seq[string] =
  var query = &"DEFINE FIELD `{column.name}` ON TABLE `{table.name}` TYPE datetime"
  var assertClause = ""
  if column.isNullable:
    query.add(" | NONE")

  if not column.isNullable:
    addAssertPart(assertClause, "$value != NONE")

  if column.isDefault and column.defaultDatetime == Current:
    query.add(&" VALUE $value OR time::now()")
  elif column.isDefault and column.defaultDatetime == CurrentOnUpdate:
    query.add(&" VALUE time::now()")
  elif column.isNullable:
    query.add(" VALUE $value OR NULL")
  else:
    query.add(" VALUE $value OR <datetime>\"1970-01-01T00:00:00Z\"")

  if column.isAutoIncrement:
    notAllowedOption("autoincrement", "decimal", column.name)

  addAssertClause(query, assertClause, column.isNullable)
  result.add(query)

  if column.isIndex:
    result.add(&"DEFINE INDEX `{table.name}_{column.name}_index` ON TABLE `{table.name}` COLUMNS `{column.name}`")

  if column.isUnique:
    result.add(&"DEFINE INDEX `{table.name}_{column.name}_unique` ON TABLE `{table.name}` COLUMNS `{column.name}` UNIQUE")

  if column.isUnsigned:
    notAllowedOption("unsigned", "varchar", column.name)


proc createTimestampsColumn(column:Column, table:Table):seq[string] =
  result.add(&"DEFINE FIELD `created_at` ON TABLE `{table.name}` TYPE datetime VALUE $value OR time::now()")
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
  var assertClause = ""
  if column.isNullable:
    query.add(" | NONE")

  if not column.isNullable:
    addAssertPart(assertClause, "$value != NONE")

  if column.isDefault:
    addValueClause(query, &"'{column.defaultString}'", column.isNullable, "''")
  else:
    addValueClause(query, "", column.isNullable, "''")

  if column.isAutoIncrement:
    notAllowedOption("autoincrement", "decimal", column.name)

  addAssertClause(query, assertClause, column.isNullable)
  result.add(query)

  if column.isIndex:
    result.add(&"DEFINE INDEX `{table.name}_{column.name}_index` ON TABLE `{table.name}` COLUMNS `{column.name}`")

  if column.isUnique:
    result.add(&"DEFINE INDEX `{table.name}_{column.name}_unique` ON TABLE `{table.name}` COLUMNS `{column.name}` UNIQUE")

  if column.isUnsigned:
    notAllowedOption("unsigned", "blob", column.name)


proc createBoolColumn(column:Column, table:Table):seq[string] =
  var query = &"DEFINE FIELD `{column.name}` ON TABLE `{table.name}` TYPE bool"
  var assertClause = ""
  if column.isNullable:
    query.add(" | NONE")

  if not column.isNullable:
    addAssertPart(assertClause, "$value != NONE")

  if column.isDefault:
    addValueClause(query, $column.defaultBool, column.isNullable, "false")
  else:
    addValueClause(query, "", column.isNullable, "false")

  if column.isAutoIncrement:
    notAllowedOption("autoincrement", "decimal", column.name)

  addAssertClause(query, assertClause, column.isNullable)
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
  var assertClause = ""
  if column.isNullable:
    query.add(" | NONE")
  
  var options:seq[string]
  for row in column.info["options"].items:
    options.add(row.getStr)
  let optionsString = enumOptionsColumn(options)
  addAssertPart(assertClause, &"$value INSIDE [{optionsString}]")

  if not column.isNullable:
    addAssertPart(assertClause, "$value != NONE")

  if column.isDefault:
    addValueClause(query, &"'{column.defaultString}'", column.isNullable, "''")
  else:
    let default = column.info["options"][0].getStr
    addValueClause(query, &"'{default}'", column.isNullable, "''")

  if column.isAutoIncrement:
    notAllowedOption("autoincrement", "decimal", column.name)

  addAssertClause(query, assertClause, column.isNullable)
  result.add(query)

  if column.isIndex:
    result.add(&"DEFINE INDEX `{table.name}_{column.name}_index` ON TABLE `{table.name}` COLUMNS `{column.name}`")

  if column.isUnique:
    result.add(&"DEFINE INDEX `{table.name}_{column.name}_unique` ON TABLE `{table.name}` COLUMNS `{column.name}` UNIQUE")

  if column.isUnsigned:
    notAllowedOption("unsigned", "enum", column.name)


proc createJsonColumn(column:Column, table:Table):seq[string] =
  var query = &"DEFINE FIELD `{column.name}` ON TABLE `{table.name}` TYPE object FLEXIBLE"
  var assertClause = ""
  if column.isNullable:
    query.add(" | NONE")

  if not column.isNullable:
    addAssertPart(assertClause, "$value != NONE")

  if column.isDefault:
    addValueClause(query, &"{$column.defaultJson}", column.isNullable, "{}")
  else:
    addValueClause(query, "", column.isNullable, "{}")

  if column.isAutoIncrement:
    notAllowedOption("autoincrement", "decimal", column.name)

  addAssertClause(query, assertClause, column.isNullable)
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
  var query = &"DEFINE FIELD `{column.name}` ON TABLE `{table.name}` TYPE record<{refTable}>"
  var assertClause = ""
  if column.isNullable:
    query.add(" | NONE")

  if not column.isNullable:
    addAssertPart(assertClause, "$value != NONE")

  if column.isDefault:
    addValueClause(query, &"{column.defaultString}", column.isNullable, "NULL")

  if column.isAutoIncrement:
    notAllowedOption("autoincrement", "decimal", column.name)
  elif column.isNullable:
    addValueClause(query, "", true, "NULL")

  addAssertClause(query, assertClause, column.isNullable)
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
