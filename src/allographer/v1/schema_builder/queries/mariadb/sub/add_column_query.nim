import std/json
import std/strformat
import ../../../enums
import ../../../models/table
import ../../../models/column
import ../schema_utils


# =============================================================================
# int
# =============================================================================
proc addSerialColumn(column:Column, table:Table):seq[string] =
  let query = &"ALTER TABLE `{table.name}` ADD COLUMN `{column.name}` BIGINT NOT NULL PRIMARY KEY AUTO_INCREMENT"
  return @[query]


proc addIntColumn(column:Column, table:Table):seq[string] =
  var query = &"ALTER TABLE `{table.name}` ADD COLUMN `{column.name}` INT"

  if column.isUnsigned:
    query.add(" UNSIGNED")

  if column.isUnique:
    query.add(" UNIQUE")

  if column.isDefault:
    query.add(&" DEFAULT {column.defaultInt}")

  if not column.isNullable:
    query.add(" NOT NULL")

  return @[query]


proc addSmallIntColumn(column:Column, table:Table):seq[string] =
  var query = &"ALTER TABLE `{table.name}` ADD COLUMN `{column.name}` SMALLINT"

  if column.isUnsigned:
    query.add(" UNSIGNED")

  if column.isUnique:
    query.add(" UNIQUE")

  if column.isDefault:
    query.add(&" DEFAULT {column.defaultInt}")

  if not column.isNullable:
    query.add(" NOT NULL")

  return @[query]


proc addMediumIntColumn(column:Column, table:Table):seq[string] =
  var query = &"ALTER TABLE `{table.name}` ADD COLUMN `{column.name}` MEDIUMINT"

  if column.isUnsigned:
    query.add(" UNSIGNED")

  if column.isUnique:
    query.add(" UNIQUE")

  if column.isDefault:
    query.add(&" DEFAULT {column.defaultInt}")

  if not column.isNullable:
    query.add(" NOT NULL")

  return @[query]


proc addBigIntColumn(column:Column, table:Table):seq[string] =
  var query = &"ALTER TABLE `{table.name}` ADD COLUMN `{column.name}` BIGINT"

  if column.isUnsigned:
    query.add(" UNSIGNED")

  if column.isUnique:
    query.add(" UNIQUE")

  if column.isDefault:
    query.add(&" DEFAULT {column.defaultInt}")

  if not column.isNullable:
    query.add(" NOT NULL")

  return @[query]


# =============================================================================
# float
# =============================================================================
proc addDecimalColumn(column:Column, table:Table):seq[string] =
  let maximum = column.info["maximum"].getInt
  let digit = column.info["digit"].getInt
  var query = &"ALTER TABLE `{table.name}` ADD COLUMN `{column.name}` DECIMAL({maximum}, {digit})"

  if column.isUnsigned:
    query.add(" UNSIGNED")

  if column.isUnique:
    query.add(" UNIQUE")

  if column.isDefault:
    query.add(&" DEFAULT {column.defaultFloat}")

  if not column.isNullable:
    query.add(" NOT NULL")

  return @[query]


proc addDoubleColumn(column:Column, table:Table):seq[string] =
  let maximum = column.info["maximum"].getInt
  let digit = column.info["digit"].getInt
  var query = &"ALTER TABLE `{table.name}` ADD COLUMN `{column.name}` DOUBLE({maximum}, {digit})"

  if column.isUnsigned:
    query.add(" UNSIGNED")

  if column.isUnique:
    query.add(" UNIQUE")

  if column.isDefault:
    query.add(&" DEFAULT {column.defaultFloat}")

  if not column.isNullable:
    query.add(" NOT NULL")

  return @[query]


proc addFloatColumn(column:Column, table:Table):seq[string] =
  var query = &"ALTER TABLE `{table.name}` ADD COLUMN `{column.name}` DOUBLE"

  if column.isUnsigned:
    query.add(" UNSIGNED")

  if column.isUnique:
    query.add(" UNIQUE")

  if column.isDefault:
    query.add(&" DEFAULT {column.defaultFloat}")

  if not column.isNullable:
    query.add(" NOT NULL")

  return @[query]


# =============================================================================
# char
# =============================================================================
proc addCharColumn(column:Column, table:Table):seq[string] =
  let maxLength = column.info["maxLength"].getInt
  var query = &"ALTER TABLE `{table.name}` ADD COLUMN `{column.name}` CHAR({maxLength})"

  if column.isUnsigned:
    notAllowedOption("unsigned", "char", column.name)

  if column.isUnique:
    query.add(" UNIQUE")

  if column.isDefault:
    query.add(&" DEFAULT '{column.defaultString}'")

  if not column.isNullable:
    query.add(" NOT NULL")

  return @[query]


proc addStringColumn(column:Column, table:Table):seq[string] =
  let maxLength = column.info["maxLength"].getInt
  var query = &"ALTER TABLE `{table.name}` ADD COLUMN `{column.name}` VARCHAR({maxLength})"

  if column.isUnsigned:
    notAllowedOption("unsigned", "string", column.name)

  if column.isUnique:
    query.add(" UNIQUE")

  if column.isDefault:
    query.add(&" DEFAULT '{column.defaultString}'")

  if not column.isNullable:
    query.add(" NOT NULL")

  return @[query]


proc addTextColumn(column:Column, table:Table):seq[string] =
  var query = &"ALTER TABLE `{table.name}` ADD COLUMN `{column.name}` TEXT"

  if column.isUnsigned:
    notAllowedOption("unsigned", "text", column.name)

  if column.isUnique:
    query.add(" UNIQUE")

  if column.isDefault:
    query.add(&" DEFAULT '{column.defaultString}'")

  if not column.isNullable:
    query.add(" NOT NULL")

  return @[query]


proc addMediumTextColumn(column:Column, table:Table):seq[string] =
  var query = &"ALTER TABLE `{table.name}` ADD COLUMN `{column.name}` MEDIUMTEXT"

  if column.isUnsigned:
    notAllowedOption("unsigned", "medium text", column.name)

  if column.isUnique:
    query.add(" UNIQUE")

  if column.isDefault:
    query.add(&" DEFAULT '{column.defaultString}'")

  if not column.isNullable:
    query.add(" NOT NULL")

  return @[query]


proc addLongTextColumn(column:Column, table:Table):seq[string] =
  var query = &"ALTER TABLE `{table.name}` ADD COLUMN `{column.name}` LONGTEXT"

  if column.isUnsigned:
    notAllowedOption("unsigned", "long text", column.name)

  if column.isUnique:
    query.add(" UNIQUE")

  if column.isDefault:
    query.add(&" DEFAULT '{column.defaultString}'")

  if not column.isNullable:
    query.add(" NOT NULL")

  return @[query]


# =============================================================================
# date
# =============================================================================
proc addDateColumn(column:Column, table:Table):seq[string] =
  var query = &"ALTER TABLE `{table.name}` ADD COLUMN `{column.name}` DATE"

  if column.isUnsigned:
    notAllowedOption("unsigned", "date", column.name)

  if column.isUnique:
    query.add(" UNIQUE")

  if not column.isNullable:
    query.add(" NOT NULL")

  if column.isDefault:
    query.add(&" DEFAULT (NOW())")

  return @[query]


proc addDatetimeColumn(column:Column, table:Table):seq[string] =
  var query = &"ALTER TABLE `{table.name}` ADD COLUMN `{column.name}` DATETIME(3)"

  if column.isUnsigned:
    notAllowedOption("unsigned", "datetime", column.name)

  if column.isUnique:
    query.add(" UNIQUE")

  if column.isDefault:
    query.add(&" DEFAULT (NOW())")

  if not column.isNullable:
    query.add(" NOT NULL")

  return @[query]


proc addTimeColumn(column:Column, table:Table):seq[string] =
  var query = &"ALTER TABLE `{table.name}` ADD COLUMN `{column.name}` TIME"

  if column.isUnsigned:
    notAllowedOption("unsigned", "time", column.name)

  if column.isUnique:
    query.add(" UNIQUE")

  if column.isDefault:
    query.add(&" DEFAULT (NOW())")

  if not column.isNullable:
    query.add(" NOT NULL")

  return @[query]


proc addTimestampColumn(column:Column, table:Table):seq[string] =
  var query = &"ALTER TABLE `{table.name}` ADD COLUMN `{column.name}` DATETIME(3)"

  if column.isUnsigned:
    notAllowedOption("unsigned", "timestamp", column.name)

  if column.isUnique:
    query.add(" UNIQUE")

  if column.isDefault:
    query.add(&" DEFAULT (NOW())")

  if not column.isNullable:
    query.add(" NOT NULL")
  
  return @[query]


proc addTimestampsColumn(column:Column, table:Table):seq[string] =
  result.add(&"ALTER TABLE `{table.name}` ADD COLUMN `addd_at` DATETIME(3)")
  result.add(&"ALTER TABLE `{table.name}` ADD COLUMN `updated_at` DATETIME(3) DEFAULT (NOW())")

proc addSoftDeleteColumn(column:Column, table:Table):seq[string] =
  var query = &"ALTER TABLE `{table.name}` ADD COLUMN deleted_at DATETIME(3)"
  return @[query]


# =============================================================================
# others
# =============================================================================
proc addBlobColumn(column:Column, table:Table):seq[string] =
  var query = &"ALTER TABLE `{table.name}` ADD COLUMN `{column.name}` BLOB"

  if column.isUnsigned:
    notAllowedOption("unsigned", "blob", column.name)

  if column.isUnique:
    query.add(" UNIQUE")

  if column.isDefault:
    query.add(&" DEFAULT '{column.defaultString}'")

  if not column.isNullable:
    query.add(" NOT NULL")

  return @[query]


proc addBoolColumn(column:Column, table:Table):seq[string] =
  var query = &"ALTER TABLE `{table.name}` ADD COLUMN `{column.name}` BOOLEAN"

  if column.isUnsigned:
    notAllowedOption("unsigned", "bool", column.name)

  if column.isUnique:
    query.add(" UNIQUE")

  if column.isDefault:
    let defaultInt = if column.defaultBool: 1 else: 0
    query.add(&" DEFAULT {defaultInt}")

  if not column.isNullable:
    query.add(" NOT NULL")

  return @[query]


proc addEnumOptions(name:string, options:seq[string]):string =
  var optionsString = ""
  for i, option in options:
    if i > 0: optionsString.add(", ")
    optionsString.add(
      &"'{option}'"
    )

  return optionsString


proc addEnumColumn(column:Column, table:Table):seq[string] =
  var options:seq[string]
  for row in column.info["options"].items:
    options.add(row.getStr)

  let optionsString = addEnumOptions(column.name, options)
  var query = &"ALTER TABLE `{table.name}` ADD COLUMN `{column.name}` ENUM({optionsString})"

  if column.isUnsigned:
    notAllowedOption("unsigned", "enum", column.name)

  if column.isUnique:
    query.add(" UNIQUE")

  if not column.isNullable:
    query.add(" NOT NULL")

  if column.isDefault:
    query.add(&" DEFAULT '{column.defaultString}'")

  return @[query]


proc addJsonColumn(column:Column, table:Table):seq[string] =
  var query = &"ALTER TABLE `{table.name}` ADD COLUMN `{column.name}` JSON"

  if column.isUnsigned:
    notAllowedOption("unsigned", "json", column.name)

  if column.isUnique:
    query.add(" UNIQUE")

  if not column.isNullable:
    query.add(" NOT NULL")

  if column.isDefault:
    query.add(&" DEFAULT '{column.defaultJson.pretty}'")

  return @[query]


# =============================================================================
# foreign key
# =============================================================================
proc addForeignColumn(column:Column, table:Table):seq[string] =
  var query = &"ALTER TABLE `{table.name}` ADD COLUMN `{column.name}` BIGINT"
  if column.isDefault:
    query.add(&" DEFAULT {column.defaultInt}")

  return @[query]

proc addStrForeignColumn(column:Column, table:Table):seq[string] =
  let maxLength = column.info["maxLength"].getInt
  var query = &"ALTER TABLE `{table.name}` ADD COLUMN `{column.name}` VARCHAR({maxLength})"
  if column.isDefault:
    query.add(&" DEFAULT {column.defaultString}")

  return @[query]


proc addForeignKey(column:Column, table:Table):string =
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
  return &"ALTER TABLE `{table.name}` ADD CONSTRAINT `{table.name}_{column.name}_fkey` FOREIGN KEY (`{column.name}`) REFERENCES `{refTable}`(`{refColumn}`) ON DELETE {onDeleteString}"


proc addIndexString(column:Column, table:Table):string =
  return &"CREATE INDEX IF NOT EXISTS `{table.name}_{column.name}_index` ON `{table.name}`(`{column.name}`)"


proc addColumnString*(table:Table, column:Column):seq[string] =
  var queries:seq[string]
  case column.typ:
    # int
  of rdbIncrements:
    queries = column.addSerialColumn(table)
  of rdbInteger:
    queries = column.addIntColumn(table)
  of rdbSmallInteger:
    queries = column.addSmallIntColumn(table)
  of rdbMediumInteger:
    queries = column.addMediumIntColumn(table)
  of rdbBigInteger:
    queries = column.addBigIntColumn(table)
    # float
  of rdbDecimal:
    queries = column.addDecimalColumn(table)
  of rdbDouble:
    queries = column.addDoubleColumn(table)
  of rdbFloat:
    queries = column.addFloatColumn(table)
    # char
  of rdbUuid:
    queries = column.addStringColumn(table)
  of rdbChar:
    queries = column.addCharColumn(table)
  of rdbString:
    queries = column.addStringColumn(table)
    # text
  of rdbText:
    queries = column.addTextColumn(table)
  of rdbMediumText:
    queries = column.addMediumTextColumn(table)
  of rdbLongText:
    queries = column.addLongTextColumn(table)
    # date
  of rdbDate:
    queries = column.addDateColumn(table)
  of rdbDatetime:
    queries = column.addDatetimeColumn(table)
  of rdbTime:
    queries = column.addTimeColumn(table)
  of rdbTimestamp:
    queries = column.addTimestampColumn(table)
  of rdbTimestamps:
    queries = column.addTimestampsColumn(table)
  of rdbSoftDelete:
    queries = column.addSoftDeleteColumn(table)
    # others
  of rdbBinary:
    queries = column.addBlobColumn(table)
  of rdbBoolean:
    queries = column.addBoolColumn(table)
  of rdbEnumField:
    queries = column.addEnumColumn(table)
  of rdbJson:
    queries = column.addJsonColumn(table)
  # foreign
  of rdbForeign:
    queries = column.addForeignColumn(table)
    queries.add(column.addForeignKey(table))
  of rdbStrForeign:
    queries = column.addStrForeignColumn(table)
    queries.add(column.addForeignKey(table))
  
  if column.isIndex:
    queries.add(column.addIndexString(table))

  return queries
