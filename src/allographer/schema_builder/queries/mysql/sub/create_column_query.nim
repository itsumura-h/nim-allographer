import std/json
import std/strformat
import ../../../enums
import ../../../models/table
import ../../../models/column
import ../schema_utils


## In MySQL, BLOB, TEXT, GEOMETRY or JSON column can't have a default value.
## BLOB/TEXT column caughn't use in key specification without a key length.

# =============================================================================
# int
# =============================================================================
proc createSerialColumn(column:Column):string =
  result = &"`{column.name}` BIGINT NOT NULL PRIMARY KEY AUTO_INCREMENT"

  if column.commentContent.len > 0:
    result.add(&" COMMENT '{column.commentContent}'")


proc createIntColumn(column:Column):string =
  result = &"`{column.name}` INT"

  if column.isAutoIncrement:
    result.add(" AUTO_INCREMENT")

  if column.isUnsigned:
    result.add(" UNSIGNED")

  if column.isUnique:
    result.add(" UNIQUE")

  if column.isDefault:
    result.add(&" DEFAULT {column.defaultInt}")

  if not column.isNullable:
    result.add(" NOT NULL")

  if column.commentContent.len > 0:
    result.add(&" COMMENT '{column.commentContent}'")


proc createSmallIntColumn(column:Column):string =
    result = &"`{column.name}` SMALLINT"

    if column.isAutoIncrement:
      result.add(" AUTO_INCREMENT")

    if column.isUnsigned:
      result.add(" UNSIGNED")

    if column.isUnique:
      result.add(" UNIQUE")

    if column.isDefault:
      result.add(&" DEFAULT {column.defaultInt}")

    if not column.isNullable:
      result.add(" NOT NULL")

    if column.commentContent.len > 0:
      result.add(&" COMMENT '{column.commentContent}'")


proc createMediumIntColumn(column:Column):string =
    result = &"`{column.name}` MEDIUMINT"

    if column.isAutoIncrement:
      result.add(" AUTO_INCREMENT")

    if column.isUnsigned:
      result.add(" UNSIGNED")

    if column.isUnique:
      result.add(" UNIQUE")

    if column.isDefault:
      result.add(&" DEFAULT {column.defaultInt}")

    if not column.isNullable:
      result.add(" NOT NULL")

    if column.commentContent.len > 0:
      result.add(&" COMMENT '{column.commentContent}'")


proc createBigIntColumn(column:Column):string =
    result = &"`{column.name}` BIGINT"

    if column.isAutoIncrement:
      result.add(" AUTO_INCREMENT")

    if column.isUnsigned:
      result.add(" UNSIGNED")

    if column.isUnique:
      result.add(" UNIQUE")

    if column.isDefault:
      result.add(&" DEFAULT {column.defaultInt}")

    if not column.isNullable:
      result.add(" NOT NULL")

    if column.commentContent.len > 0:
      result.add(&" COMMENT '{column.commentContent}'")


# =============================================================================
# float
# =============================================================================
proc createDecimalColumn(column:Column):string =
  let maximum = column.info["maximum"].getInt
  let digit = column.info["digit"].getInt
  result = &"`{column.name}` DECIMAL({maximum}, {digit})"

  if column.isUnsigned:
    result.add(" UNSIGNED")

  if column.isUnique:
    result.add(" UNIQUE")

  if column.isDefault:
    result.add(&" DEFAULT {column.defaultFloat}")

  if not column.isNullable:
    result.add(" NOT NULL")

  if column.commentContent.len > 0:
    result.add(&" COMMENT '{column.commentContent}'")


proc createDoubleColumn(column:Column):string =
  let maximum = column.info["maximum"].getInt
  let digit = column.info["digit"].getInt
  result = &"`{column.name}` DOUBLE({maximum}, {digit})"

  if column.isUnsigned:
    result.add(" UNSIGNED")

  if column.isUnique:
    result.add(" UNIQUE")

  if column.isDefault:
    result.add(&" DEFAULT {column.defaultFloat}")

  if not column.isNullable:
    result.add(" NOT NULL")

  if column.commentContent.len > 0:
    result.add(&" COMMENT '{column.commentContent}'")


proc createFloatColumn(column:Column):string =
  result = &"`{column.name}` DOUBLE"

  if column.isUnsigned:
    result.add(" UNSIGNED")

  if column.isUnique:
    result.add(" UNIQUE")

  if column.isDefault:
    result.add(&" DEFAULT {column.defaultFloat}")

  if not column.isNullable:
    result.add(" NOT NULL")

  if column.commentContent.len > 0:
    result.add(&" COMMENT '{column.commentContent}'")


# =============================================================================
# char
# =============================================================================
proc createCharColumn(column:Column):string =
  let maxLength = column.info["maxLength"].getInt
  result = &"`{column.name}` CHAR({maxLength})"

  if column.isUnsigned:
    notAllowedOption("unsigned", "char", column.name)

  if column.isUnique:
    result.add(" UNIQUE")

  if column.isDefault:
    result.add(&" DEFAULT '{column.defaultString}'")

  if not column.isNullable:
    result.add(" NOT NULL")

  if column.commentContent.len > 0:
    result.add(&" COMMENT '{column.commentContent}'")


proc createStringColumn(column:Column):string =
  let maxLength = column.info["maxLength"].getInt
  result = &"`{column.name}` VARCHAR({maxLength})"

  if column.isUnsigned:
    notAllowedOption("unsigned", "string", column.name)

  if column.isUnique:
    result.add(" UNIQUE")

  if column.isDefault:
    result.add(&" DEFAULT '{column.defaultString}'")

  if not column.isNullable:
    result.add(" NOT NULL")

  if column.commentContent.len > 0:
    result.add(&" COMMENT '{column.commentContent}'")


proc createTextColumn(column:Column):string =
  result = &"`{column.name}` TEXT"

  if column.isUnsigned:
    notAllowedOption("unsigned", "text", column.name)

  if column.isUnique:
    notAllowedOption("unique", "text", column.name)

  if column.isDefault:
    notAllowedOption("default", "text", column.name)

  if column.isIndex:
    notAllowedOption("index", "text", column.name)

  if not column.isNullable:
    result.add(" NOT NULL")

  if column.commentContent.len > 0:
    result.add(&" COMMENT '{column.commentContent}'")


proc createMediumTextColumn(column:Column):string =
  result = &"`{column.name}` MEDIUMTEXT"

  if column.isUnsigned:
    notAllowedOption("unsigned", "medium text", column.name)

  if column.isUnique:
    notAllowedOption("unique", "medium text", column.name)

  if column.isDefault:
    notAllowedOption("default", "text", column.name)

  if column.isIndex:
    notAllowedOption("index", "text", column.name)

  if not column.isNullable:
    result.add(" NOT NULL")

  if column.commentContent.len > 0:
    result.add(&" COMMENT '{column.commentContent}'")


proc createLongTextColumn(column:Column):string =
  result = &"`{column.name}` LONGTEXT"

  if column.isUnsigned:
    notAllowedOption("unsigned", "long text", column.name)

  if column.isUnique:
    notAllowedOption("unique", "long text", column.name)

  if column.isDefault:
    notAllowedOption("default", "text", column.name)

  if column.isIndex:
    notAllowedOption("index", "text", column.name)

  if not column.isNullable:
    result.add(" NOT NULL")

  if column.commentContent.len > 0:
    result.add(&" COMMENT '{column.commentContent}'")


# =============================================================================
# date
# =============================================================================
proc createDateColumn(column:Column):string =
  result = &"`{column.name}` DATE"

  if column.isUnsigned:
    notAllowedOption("unsigned", "date", column.name)

  if column.isUnique:
    result.add(" UNIQUE")

  if not column.isNullable:
    result.add(" NOT NULL")

  if column.isDefault:
    result.add(&" DEFAULT (NOW())")

  if column.commentContent.len > 0:
    result.add(&" COMMENT '{column.commentContent}'")


proc createDatetimeColumn(column:Column):string =
  # result = &"`{column.name}` DATETIME(3)"
  result = &"`{column.name}` DATETIME"

  if column.isUnsigned:
    notAllowedOption("unsigned", "datetime", column.name)

  if column.isUnique:
    result.add(" UNIQUE")

  if column.isDefault:
    result.add(&" DEFAULT (NOW())")

  if not column.isNullable:
    result.add(" NOT NULL")

  if column.commentContent.len > 0:
    result.add(&" COMMENT '{column.commentContent}'")


proc createTimeColumn(column:Column):string =
  result = &"`{column.name}` TIME"

  if column.isUnsigned:
    notAllowedOption("unsigned", "time", column.name)

  if column.isUnique:
    result.add(" UNIQUE")

  if column.isDefault:
    result.add(&" DEFAULT (NOW())")

  if not column.isNullable:
    result.add(" NOT NULL")

  if column.commentContent.len > 0:
    result.add(&" COMMENT '{column.commentContent}'")


proc createTimestampColumn(column:Column):string =
  result = &"`{column.name}` DATETIME(3)"

  if column.isUnsigned:
    notAllowedOption("unsigned", "timestamp", column.name)

  if column.isUnique:
    result.add(" UNIQUE")

  if column.isDefault:
    result.add(&" DEFAULT (NOW())")

  if not column.isNullable:
    result.add(" NOT NULL")

  if column.commentContent.len > 0:
    result.add(&" COMMENT '{column.commentContent}'")


proc createTimestampsColumn(column:Column):string =
  result = "`created_at` DATETIME(3)"
  if column.commentContent.len > 0:
    result.add(&" COMMENT '{column.commentContent}'")

  result.add(", ")

  result.add("`updated_at` DATETIME(3) DEFAULT (NOW())")
  if column.commentContent.len > 0:
    result.add(&" COMMENT '{column.commentContent}'")


proc createSoftDeleteColumn(column:Column):string =
  result = "`deleted_at` DATETIME(3)"

  if column.commentContent.len > 0:
    result.add(&" COMMENT '{column.commentContent}'")


# =============================================================================
# others
# =============================================================================
proc createBlobColumn(column:Column):string =
  result = &"`{column.name}` BLOB"

  if column.isUnsigned:
    notAllowedOption("unsigned", "blob", column.name)

  if column.isUnique:
    notAllowedOption("unique", "blob", column.name)

  if column.isDefault:
    notAllowedOption("default", "binary", column.name)

  if column.isIndex:
    notAllowedOption("index", "binary", column.name)

  if not column.isNullable:
    result.add(" NOT NULL")

  if column.commentContent.len > 0:
    result.add(&" COMMENT '{column.commentContent}'")


proc createBoolColumn(column:Column):string =
  result = &"`{column.name}` BOOLEAN"

  if column.isUnsigned:
    notAllowedOption("unsigned", "bool", column.name)

  if column.isUnique:
    result.add(" UNIQUE")

  if column.isDefault:
    let defaultInt = if column.defaultBool: 1 else: 0
    result.add(&" DEFAULT {defaultInt}")

  if not column.isNullable:
      result.add(" NOT NULL")


proc createEnumOptions(name:string, options:seq[string]):string =
  var optionsString = ""
  for i, option in options:
    if i > 0: optionsString.add(", ")
    optionsString.add(
      &"'{option}'"
    )

  return optionsString

proc createEnumColumn(column:Column):string =
  var options:seq[string]
  for row in column.info["options"].items:
    options.add(row.getStr)

  let optionsString = createEnumOptions(column.name, options)
  result = &"`{column.name}` ENUM({optionsString})"

  if column.isUnsigned:
    notAllowedOption("unsigned", "enum", column.name)

  if column.isUnique:
    result.add(" UNIQUE")

  if not column.isNullable:
    result.add(" NOT NULL")

  if column.isDefault:
    result.add(&" DEFAULT '{column.defaultString}'")

  if column.commentContent.len > 0:
    result.add(&" COMMENT '{column.commentContent}'")


proc createJsonColumn(column:Column):string =
  result = &"`{column.name}` JSON"

  if column.isUnsigned:
    notAllowedOption("unsigned", "json", column.name)

  if column.isUnique:
    notAllowedOption("unique", "json", column.name)

  if not column.isNullable:
    result.add(" NOT NULL")

  if column.isDefault:
    notAllowedOption("default", "json", column.name)

  if column.isIndex:
    notAllowedOption("index", "json", column.name)

  if column.commentContent.len > 0:
    result.add(&" COMMENT '{column.commentContent}'")


# =============================================================================
# foreign key
# =============================================================================
proc createForeignColumn(column:Column):string =
  result = &"`{column.name}` BIGINT"
  if column.isDefault:
    result.add(&" DEFAULT {column.defaultInt}")

  if column.commentContent.len > 0:
    result.add(&" COMMENT '{column.commentContent}'")

proc createStrForeignColumn(column:Column):string =
  let maxLength = column.info["maxLength"].getInt
  result = &"`{column.name}` VARCHAR({maxLength})"
  
  if column.isDefault:
    result.add(&" DEFAULT {column.defaultString}")

  if column.commentContent.len > 0:
    result.add(&" COMMENT '{column.commentContent}'")


proc createForeignKey*(table:Table, column:Column):string =
  let onDeleteString =
    case column.foreignOnDelete
    of RESTRICT:
      "RESTRICT"
    of CASCADE:
      "CASCADE"
    of SET_NULL:
      "SET NULL"
    of NO_ACTION:
      "NO ACTION"
  
  let refColumn = column.info["column"].getStr
  let refTable = column.info["table"].getStr
  return &"FOREIGN KEY `{table.name}_{column.name}_fkey` (`{column.name}`) REFERENCES `{refTable}`(`{refColumn}`) ON DELETE {onDeleteString}"

proc alterAddForeignKey*(column:Column, table:Table):string =
  let onDeleteString =
    case column.foreignOnDelete
    of RESTRICT:
      "RESTRICT"
    of CASCADE:
      "CASCADE"
    of SET_NULL:
      "SET NULL"
    of NO_ACTION:
      "NO ACTION"
  
  let tableName = table.name
  let constraintName = &"{tableName}_{column.name}"
  let refTable = column.info["table"].getStr
  let refColumn = column.info["column"].getStr
  return &"CONSTRAINT `{constraintName}` FOREIGN KEY (`{column.name}`) REFERENCES `{refTable}`({refColumn}) ON DELETE {onDeleteString}"

# proc alterDeleteColumn*(column:Column, table:Table):string =
#   var table = table.name
#   return &"ALTER TABLE `{table}` DROP `{column.name}`"

# proc alterDeleteForeignColumn*(column:Column, table:Table):string =
#   var tableName = table.name
#   var constraintName = &"{tableName}_{column.name}"
#   return &"ALTER TABLE `{table.name}` DROP FOREIGN KEY `{constraintName}`"

proc createIndexString*(table:Table, column:Column):string =
  return &"CREATE INDEX `{table.name}_{column.name}_index` ON `{table.name}`(`{column.name}`)"


proc createColumnString*(table:Table, column:Column):string =
  case column.typ:
    # int
  of rdbIncrements:
    return column.createSerialColumn()
  of rdbInteger:
    return column.createIntColumn()
  of rdbSmallInteger:
    return column.createSmallIntColumn()
  of rdbMediumInteger:
    return column.createMediumIntColumn()
  of rdbBigInteger:
    return column.createBigIntColumn()
    # float
  of rdbDecimal:
    return column.createDecimalColumn()
  of rdbDouble:
    # return column.createDecimalColumn()
    return column.createDoubleColumn()
  of rdbFloat:
    return column.createFloatColumn()
    # char
  of rdbUuid:
    return column.createStringColumn()
  of rdbChar:
    return column.createCharColumn()
  of rdbString:
    return column.createStringColumn()
    # text
  of rdbText:
    return column.createTextColumn()
  of rdbMediumText:
    return column.createMediumTextColumn()
  of rdbLongText:
    return column.createLongTextColumn()
    # date
  of rdbDate:
    return column.createDateColumn()
  of rdbDatetime:
    return column.createDatetimeColumn()
  of rdbTime:
    return column.createTimeColumn()
  of rdbTimestamp:
    return column.createTimestampColumn()
  of rdbTimestamps:
    return column.createTimestampsColumn()
  of rdbSoftDelete:
    return column.createSoftDeleteColumn()
    # others
  of rdbBinary:
    return column.createBlobColumn()
  of rdbBoolean:
    return column.createBoolColumn()
  of rdbEnumField:
    return column.createEnumColumn()
  of rdbJson:
    return column.createJsonColumn()
  # foreign
  of rdbForeign:
    return column.createForeignColumn()
  of rdbStrForeign:
    return column.createStrForeignColumn()
