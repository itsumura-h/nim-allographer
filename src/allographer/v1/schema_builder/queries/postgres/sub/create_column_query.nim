import std/json
import std/strformat
import ../../../enums
import ../../../models/table
import ../../../models/column
import ../schema_utils


# =============================================================================
# int
# =============================================================================
proc createSerialColumn(column:Column, table:Table):string =
  result = &"\"{column.name}\" BIGSERIAL NOT NULL PRIMARY KEY"


proc createIntColumn(column:Column, table:Table):string =
  if column.isAutoIncrement:
    result = &"\"{column.name}\" BIGSERIAL"
  else:
    result = &"\"{column.name}\" INTEGER"

  if column.isUnique:
    result.add(&" CONSTRAINT \"{table.name}_{column.name}_unique\" UNIQUE")

  if not column.isNullable:
    result.add(" NOT NULL")

  if column.isDefault:
    result.add(&" DEFAULT {column.defaultInt}")

  if column.isUnsigned:
    result.add(&" CHECK (\"{column.name}\" >= 0)")


proc createSmallIntColumn(column:Column, table:Table):string =
  result = &"\"{column.name}\" SMALLINT"

  if column.isAutoIncrement:
    notAllowedOption("autoincrement", "smallint", column.name)

  if column.isUnique:
    result.add(&" CONSTRAINT \"{table.name}_{column.name}_unique\" UNIQUE")

  if not column.isNullable:
    result.add(" NOT NULL")

  if column.isDefault:
    result.add(&" DEFAULT {column.defaultInt}")

  if column.isUnsigned:
    result.add(&" CHECK (\"{column.name}\" >= 0)")


proc createMediumIntColumn(column:Column, table:Table):string =
  if column.isAutoIncrement:
    result = &"\"{column.name}\" BIGSERIAL"
  else:
    result = &"\"{column.name}\" INTEGER"

  if column.isUnique:
    result.add(&" CONSTRAINT \"{table.name}_{column.name}_unique\" UNIQUE")

  if not column.isNullable:
    result.add(" NOT NULL")

  if column.isDefault:
    result.add(&" DEFAULT {column.defaultInt}")

  if column.isUnsigned:
    result.add(&" CHECK (\"{column.name}\" >= 0)")


proc createBigIntColumn(column:Column, table:Table):string =
  if column.isAutoIncrement:
    result = &"\"{column.name}\" BIGSERIAL"
  else:
    result = &"\"{column.name}\" BIGINT"

  if column.isUnique:
    result.add(&" CONSTRAINT \"{table.name}_{column.name}_unique\" UNIQUE")

  if not column.isNullable:
    result.add(" NOT NULL")

  if column.isDefault:
    result.add(&" DEFAULT {column.defaultInt}")

  if column.isUnsigned:
    result.add(&" CHECK (\"{column.name}\" >= 0)")


# =============================================================================
# float
# =============================================================================
proc createDecimalColumn(column:Column, table:Table):string =
  let maximum = column.info["maximum"].getInt
  let digit = column.info["digit"].getInt
  result = &"\"{column.name}\" NUMERIC({maximum}, {digit})"

  if column.isUnique:
    result.add(&" CONSTRAINT \"{table.name}_{column.name}_unique\" UNIQUE")

  if not column.isNullable:
    result.add(" NOT NULL")

  if column.isDefault:
    result.add(&" DEFAULT {column.defaultFloat}")

  if column.isUnsigned:
    result.add(&" CHECK (\"{column.name}\" >= 0)")


proc createFloatColumn(column:Column, table:Table):string =
  result = &"\"{column.name}\" NUMERIC"

  if column.isUnique:
    result.add(&" CONSTRAINT \"{table.name}_{column.name}_unique\" UNIQUE")

  if not column.isNullable:
    result.add(" NOT NULL")

  if column.isDefault:
    result.add(&" DEFAULT {column.defaultFloat}")

  if column.isUnsigned:
    result.add(&" CHECK (\"{column.name}\" >= 0)")


# =============================================================================
# char
# =============================================================================
proc createCharColumn(column:Column, table:Table):string =
  let maxLength = column.info["maxLength"].getInt
  result = &"\"{column.name}\" CHAR({maxLength})"

  if column.isUnique:
    result.add(&" CONSTRAINT \"{table.name}_{column.name}_unique\" UNIQUE")

  if not column.isNullable:
    result.add(" NOT NULL")

  if column.isDefault:
    result.add(&" DEFAULT '{column.defaultString}'")

  if column.isUnsigned:
    notAllowedOption("unsigned", "char", column.name)


proc createStringColumn(column:Column, table:Table):string =
  let maxLength = column.info["maxLength"].getInt
  result = &"\"{column.name}\" VARCHAR({maxLength})"

  if column.isUnique:
    result.add(&" CONSTRAINT \"{table.name}_{column.name}_unique\" UNIQUE")

  if not column.isNullable:
    result.add(" NOT NULL")

  if column.isDefault:
    result.add(&" DEFAULT '{column.defaultString}'")

  if column.isUnsigned:
    notAllowedOption("unsigned", "string", column.name)


proc createTextColumn(column:Column, table:Table):string =
  result = &"\"{column.name}\" TEXT"

  if column.isUnique:
    result.add(&" CONSTRAINT \"{table.name}_{column.name}_unique\" UNIQUE")

  if not column.isNullable:
    result.add(" NOT NULL")

  if column.isDefault:
    result.add(&" DEFAULT '{column.defaultString}'")

  if column.isUnsigned:
    notAllowedOption("unsigned", "text", column.name)


# =============================================================================
# date
# =============================================================================
proc createDateColumn(column:Column, table:Table):string =
  result = &"\"{column.name}\" DATE"

  if column.isUnique:
    result.add(&" CONSTRAINT \"{table.name}_{column.name}_unique\" UNIQUE")

  if not column.isNullable:
    result.add(" NOT NULL")

  if column.isDefault:
    result.add(&" DEFAULT (NOW())")

  if column.isUnsigned:
    notAllowedOption("unsigned", "date", column.name)


proc createDatetimeColumn(column:Column, table:Table):string =
  result = &"\"{column.name}\" TIMESTAMP"

  if column.isUnique:
    result.add(&" CONSTRAINT \"{table.name}_{column.name}_unique\" UNIQUE")

  if not column.isNullable:
    result.add(" NOT NULL")

  if column.isDefault:
    result.add(&" DEFAULT (NOW())")

  if column.isUnsigned:
    notAllowedOption("unsigned", "date", column.name)


proc createTimeColumn(column:Column, table:Table):string =
  result = &"\"{column.name}\" TIME"

  if column.isUnique:
    result.add(&" CONSTRAINT \"{table.name}_{column.name}_unique\" UNIQUE")

  if not column.isNullable:
    result.add(" NOT NULL")

  if column.isDefault:
    result.add(&" DEFAULT (NOW())")

  if column.isUnsigned:
    notAllowedOption("unsigned", "date", column.name)


proc createTimestampColumn(column:Column, table:Table):string =
  result = &"\"{column.name}\" TIMESTAMP"

  if column.isUnique:
    result.add(&" CONSTRAINT \"{table.name}_{column.name}_unique\" UNIQUE")

  if not column.isNullable:
    result.add(" NOT NULL")

  if column.isDefault:
    result.add(&" DEFAULT (NOW())")

  if column.isUnsigned:
    notAllowedOption("unsigned", "date", column.name)


proc createTimestampsColumn(column:Column, table:Table):string =
  result = "\"created_at\" TIMESTAMP DEFAULT CURRENT_TIMESTAMP, "
  result.add("\"updated_at\" TIMESTAMP DEFAULT CURRENT_TIMESTAMP")


proc createSoftDeleteColumn(column:Column, table:Table):string =
  result = "\"deleted_at\" TIMESTAMP"


# =============================================================================
# others
# =============================================================================
proc createBlobColumn(column:Column, table:Table):string =
  result = &"\"{column.name}\" BYTEA"

  if column.isUnique:
    result.add(&" CONSTRAINT \"{table.name}_{column.name}_unique\" UNIQUE")

  if not column.isNullable:
    result.add(" NOT NULL")

  if column.isDefault:
    result.add(&" DEFAULT '{column.defaultString}'")

  if column.isUnsigned:
    notAllowedOption("unsigned", "blob", column.name)


proc createBoolColumn(column:Column, table:Table):string =
  result = &"\"{column.name}\" BOOLEAN"

  if column.isUnique:
    result.add(&" CONSTRAINT \"{table.name}_{column.name}_unique\" UNIQUE")

  if not column.isNullable:
    result.add(" NOT NULL")

  if column.isDefault:
    result.add(&" DEFAULT {column.defaultBool}")

  if column.isUnsigned:
    notAllowedOption("unsigned", "bool", column.name)


proc enumOptionsGenerator(name:string, options:seq[string]):string =
  var optionsString = ""
  for i, option in options:
    if i > 0: optionsString.add(" OR ")
    optionsString.add(
      &"\"{name}\" = '{option}'"
    )

  return optionsString


proc createEnumColumn(column:Column, table:Table):string =
  result = &"\"{column.name}\" CHARACTER"

  if column.isUnique:
    result.add(&" CONSTRAINT \"{table.name}_{column.name}_unique\" UNIQUE")

  if not column.isNullable:
    result.add(" NOT NULL")

  if column.isDefault:
    result.add(&" DEFAULT '{column.defaultString}'")

  if column.isUnsigned:
    notAllowedOption("unsigned", "text", column.name)

  var options:seq[string]
  for row in column.info["options"].items:
    options.add(row.getStr)

  let optionsString = enumOptionsGenerator(column.name, options)
  result.add(&" CHECK ({optionsString})")


proc createJsonColumn(column:Column, table:Table):string =
  result = &"\"{column.name}\" JSONB"

  if column.isUnique:
    result.add(&" CONSTRAINT \"{table.name}_{column.name}_unique\" UNIQUE")

  if column.isDefault:
    result.add(&" DEFAULT '{column.defaultJson.pretty}'")

  if column.isUnsigned:
    notAllowedOption("unsigned", "json", column.name)


proc createForeignColumn(column:Column, table:Table):string =
  result = &"\"{column.name}\" INT"
  
  if column.isDefault:
    result.add(&" DEFAULT {column.defaultInt}")


proc createStrForeignColumn(column:Column, table:Table):string =
  let maxLength = column.info["maxLength"].getInt
  result = &"\"{column.name}\" VARCHAR({maxLength})"

  if column.isDefault:
    result.add(&" DEFAULT {column.defaultString}")


proc createForeignKey(column:Column, table:Table):string =
  var onDeleteString = "RESTRICT"
  if column.foreignOnDelete == CASCADE:
    onDeleteString = "CASCADE"
  elif column.foreignOnDelete == SET_NULL:
    onDeleteString = "SET NULL"
  elif column.foreignOnDelete == NO_ACTION:
    onDeleteString = "NO ACTION"

  let refColumn = column.info["column"].getStr
  let refTable = column.info["table"].getStr
  return &"FOREIGN KEY(\"{column.name}\") REFERENCES \"{refTable}\"(\"{refColumn}\") ON DELETE {onDeleteString}"


proc indexColumn(column:Column, table:Table):string =
  return &"CREATE INDEX IF NOT EXISTS \"{table.name}_{column.name}_index\" ON \"{table.name}\"(\"{column.name}\")"


proc updatedAtColumn(column:Column, table:Table):seq[string] =
  return @[
    &"""CREATE OR REPLACE FUNCTION {table.name}_updated_at_column()
    RETURNS TRIGGER AS $$
    BEGIN
        NEW.updated_at = CURRENT_TIMESTAMP;
        RETURN NEW;
    END;
    $$ LANGUAGE plpgsql;""",
    
    &"""CREATE TRIGGER set_{table.name}_updated_at
    BEFORE UPDATE ON "{table.name}"
    FOR EACH ROW
    EXECUTE FUNCTION {table.name}_updated_at_column();"""
  ]


proc createColumnString*(table:Table, column:Column):string =
  case column.typ:
    # int
  of rdbIncrements:
    return column.createSerialColumn(table)
  of rdbInteger:
    return column.createIntColumn(table)
  of rdbSmallInteger:
    return column.createSmallIntColumn(table)
  of rdbMediumInteger:
    return column.createMediumIntColumn(table)
  of rdbBigInteger:
    return column.createBigIntColumn(table)
    # float
  of rdbDecimal:
    return column.createDecimalColumn(table)
  of rdbDouble:
    return column.createDecimalColumn(table)
  of rdbFloat:
    return column.createFloatColumn(table)
    # char
  of rdbUuid:
    return column.createStringColumn(table)
  of rdbChar:
    return column.createCharColumn(table)
  of rdbString:
    return column.createStringColumn(table)
    # text
  of rdbText:
    return column.createTextColumn(table)
  of rdbMediumText:
    return column.createTextColumn(table)
  of rdbLongText:
    return column.createTextColumn(table)
    # date
  of rdbDate:
    return column.createDateColumn(table)
  of rdbDatetime:
    return column.createDatetimeColumn(table)
  of rdbTime:
    return column.createTimeColumn(table)
  of rdbTimestamp:
    return column.createTimestampColumn(table)
  of rdbTimestamps:
    return column.createTimestampsColumn(table)
  of rdbSoftDelete:
    return column.createSoftDeleteColumn(table)
    # others
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
    return column.createStrForeignColumn(table)


proc createForeignString*(table:Table, column:Column):string =
  return column.createForeignKey(table)


proc createIndexString*(table:Table, column:Column):string =
  return column.indexColumn(table)

proc createUpdatedAtString*(table:Table, column:Column):seq[string] =
  return column.updatedAtColumn(table)
