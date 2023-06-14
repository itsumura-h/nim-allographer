import json, strformat
import ../../grammars
import ../generator_utils

# =============================================================================
# int
# =============================================================================
proc serialGenerator*(column:Column):string =
  result = &"`{column.name}` BIGINT NOT NULL PRIMARY KEY AUTO_INCREMENT"

proc intGenerator*(column:Column):string =
  result = &"`{column.name}` INT"

  if column.isUnsigned:
    result.add(" UNSIGNED")

  if column.isUnique:
    result.add(" UNIQUE")

  if column.isDefault:
    result.add(&" DEFAULT {column.defaultInt}")

  if not column.isNullable:
    result.add(" NOT NULL")

proc smallIntGenerator*(column:Column):string =
    result = &"`{column.name}` SMALLINT"

    if column.isUnsigned:
      result.add(" UNSIGNED")

    if column.isUnique:
      result.add(" UNIQUE")

    if column.isDefault:
      result.add(&" DEFAULT {column.defaultInt}")

    if not column.isNullable:
      result.add(" NOT NULL")

proc mediumIntGenerator*(column:Column):string =
    result = &"`{column.name}` MEDIUMINT"

    if column.isUnsigned:
      result.add(" UNSIGNED")

    if column.isUnique:
      result.add(" UNIQUE")

    if column.isDefault:
      result.add(&" DEFAULT {column.defaultInt}")

    if not column.isNullable:
      result.add(" NOT NULL")

proc bigIntGenerator*(column:Column):string =
    result = &"`{column.name}` BIGINT"

    if column.isUnsigned:
      result.add(" UNSIGNED")

    if column.isUnique:
      result.add(" UNIQUE")

    if column.isDefault:
      result.add(&" DEFAULT {column.defaultInt}")

    if not column.isNullable:
      result.add(" NOT NULL")

# =============================================================================
# float
# =============================================================================
proc decimalGenerator*(column:Column):string =
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

proc doubleGenerator*(column:Column):string =
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

proc floatGenerator*(column:Column):string =
  result = &"`{column.name}` DOUBLE"

  if column.isUnsigned:
    result.add(" UNSIGNED")

  if column.isUnique:
    result.add(" UNIQUE")

  if column.isDefault:
    result.add(&" DEFAULT {column.defaultFloat}")

  if not column.isNullable:
    result.add(" NOT NULL")

# =============================================================================
# char
# =============================================================================
proc charGenerator*(column:Column):string =
  let maxLength = column.info["maxLength"].getInt
  result = &"`{column.name}` CHAR({maxLength})"

  if column.isUnsigned:
    notAllowed("unsigned", "char", column.name)

  if column.isUnique:
    result.add(" UNIQUE")

  if column.isDefault:
    result.add(&" DEFAULT '{column.defaultString}'")

  if not column.isNullable:
    result.add(" NOT NULL")

proc stringGenerator*(column:Column):string =
  let maxLength = column.info["maxLength"].getInt
  result = &"`{column.name}` VARCHAR({maxLength})"

  if column.isUnsigned:
    notAllowed("unsigned", "string", column.name)

  if column.isUnique:
    result.add(" UNIQUE")

  if column.isDefault:
    result.add(&" DEFAULT '{column.defaultString}'")

  if not column.isNullable:
    result.add(" NOT NULL")

proc textGenerator*(column:Column):string =
  result = &"`{column.name}` TEXT"

  if column.isUnsigned:
    notAllowed("unsigned", "text", column.name)

  if column.isUnique:
    notAllowed("unique", "text", column.name)

  if column.isDefault:
    result.add(&" DEFAULT '{column.defaultString}'")

  if not column.isNullable:
    result.add(" NOT NULL")

proc mediumTextGenerator*(column:Column):string =
  result = &"`{column.name}` MEDIUMTEXT"

  if column.isUnsigned:
    notAllowed("unsigned", "medium text", column.name)

  if column.isUnique:
    notAllowed("unique", "medium text", column.name)

  if column.isDefault:
    result.add(&" DEFAULT '{column.defaultString}'")

  if not column.isNullable:
    result.add(" NOT NULL")

proc longTextGenerator*(column:Column):string =
  result = &"`{column.name}` LONGTEXT"

  if column.isUnsigned:
    notAllowed("unsigned", "long text", column.name)

  if column.isUnique:
    notAllowed("unique", "long text", column.name)

  if column.isDefault:
    result.add(&" DEFAULT '{column.defaultString}'")

  if not column.isNullable:
    result.add(" NOT NULL")

# =============================================================================
# date
# =============================================================================
proc dateGenerator*(column:Column):string =
  result = &"`{column.name}` DATE"

  if column.isUnsigned:
    notAllowed("unsigned", "date", column.name)

  if column.isUnique:
    result.add(" UNIQUE")

  if not column.isNullable:
    result.add(" NOT NULL")

  if column.isDefault:
    result.add(&" DEFAULT (NOW())")

proc datetimeGenerator*(column:Column):string =
  result = &"`{column.name}` DATETIME"

  if column.isUnsigned:
    notAllowed("unsigned", "datetime", column.name)

  if column.isUnique:
    result.add(" UNIQUE")

  if column.isDefault:
    result.add(&" DEFAULT (NOW())")

  if not column.isNullable:
    result.add(" NOT NULL")

proc timeGenerator*(column:Column):string =
  result = &"`{column.name}` TIME"

  if column.isUnsigned:
    notAllowed("unsigned", "time", column.name)

  if column.isUnique:
    result.add(" UNIQUE")

  if column.isDefault:
    result.add(&" DEFAULT (NOW())")

  if not column.isNullable:
    result.add(" NOT NULL")

proc timestampGenerator*(column:Column):string =
  result = &"`{column.name}` DATETIME"

  if column.isUnsigned:
    notAllowed("unsigned", "timestamp", column.name)

  if column.isUnique:
    result.add(" UNIQUE")

  if column.isDefault:
    result.add(&" DEFAULT (NOW())")

  if not column.isNullable:
      result.add(" NOT NULL")

proc timestampsGenerator*(column:Column):string =
  result = "`created_at` DATETIME, "
  result.add("`updated_at` DATETIME DEFAULT (NOW())")

proc softDeleteGenerator*(column:Column):string =
  result = "`deleted_at` DATETIME"

# =============================================================================
# others
# =============================================================================
proc blobGenerator*(column:Column):string =
  result = &"`{column.name}` BLOB"

  if column.isUnsigned:
    notAllowed("unsigned", "blob", column.name)

  if column.isUnique:
    notAllowed("unique", "blob", column.name)

  if column.isDefault:
    result.add(&" DEFAULT '{column.defaultString}'")

  if not column.isNullable:
      result.add(" NOT NULL")

proc boolGenerator*(column:Column):string =
  result = &"`{column.name}` BOOLEAN"

  if column.isUnsigned:
    notAllowed("unsigned", "bool", column.name)

  if column.isUnique:
    result.add(" UNIQUE")

  if column.isDefault:
    let defaultInt = if column.defaultBool: 1 else: 0
    result.add(&" DEFAULT {defaultInt}")

  if not column.isNullable:
      result.add(" NOT NULL")

proc enumOptionsGenerator(name:string, options:seq[string]):string =
  var optionsString = ""
  for i, option in options:
    if i > 0: optionsString.add(", ")
    optionsString.add(
      &"'{option}'"
    )

  return optionsString

proc enumGenerator*(column:Column):string =
  var options:seq[string]
  for row in column.info["options"].items:
    options.add(row.getStr)

  let optionsString = enumOptionsGenerator(column.name, options)
  result = &"`{column.name}` ENUM({optionsString})"

  if column.isUnsigned:
    notAllowed("unsigned", "enum", column.name)

  if column.isUnique:
    result.add(" UNIQUE")

  if not column.isNullable:
    result.add(" NOT NULL")

  if column.isDefault:
    result.add(&" DEFAULT '{column.defaultString}'")

proc jsonGenerator*(column:Column):string =
  result = &"`{column.name}` JSON"

  if column.isUnsigned:
    notAllowed("unsigned", "json", column.name)

  if column.isUnique:
    notAllowed("unique", "json", column.name)

  if not column.isNullable:
    result.add(" NOT NULL")

  if column.isDefault:
    result.add(&" DEFAULT '{column.defaultJson.pretty}'")
    # notAllowed("default value", "json", column.name)

# =============================================================================
# foreign key
# =============================================================================
proc foreignColumnGenerator*(column:Column):string =
  result = &"`{column.name}` BIGINT"
  if column.isDefault:
    result.add(&" DEFAULT {column.defaultInt}")

proc strForeignColumnGenerator*(column:Column):string =
  let maxLength = column.info["maxLength"].getInt
  result = &"`{column.name}` VARCHAR({maxLength})"
  if column.isDefault:
    result.add(&" DEFAULT {column.defaultString}")

proc foreignGenerator*(column:Column):string =
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
  return &"FOREIGN KEY(`{column.name}`) REFERENCES `{refTable}`(`{refColumn}`) ON DELETE {onDeleteString}"

proc alterAddForeignGenerator*(column:Column, table:Table):string =
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

# proc alterDeleteGenerator*(column:Column, table:Table):string =
#   var table = table.name
#   return &"ALTER TABLE `{table}` DROP `{column.name}`"

# proc alterDeleteForeignGenerator*(column:Column, table:Table):string =
#   var tableName = table.name
#   var constraintName = &"{tableName}_{column.name}"
#   return &"ALTER TABLE `{table.name}` DROP FOREIGN KEY `{constraintName}`"

# proc indexGenerate*(column:Column, table:Table):string =
#   var table = table.name
#   let smallTable = table.toLowerAscii()
#   return &"CREATE INDEX `{smallTable}_{column.name}_index` ON `{table}`(`{column.name}`)"
