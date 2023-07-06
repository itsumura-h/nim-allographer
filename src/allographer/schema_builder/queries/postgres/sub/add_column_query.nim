import std/json
import std/strformat
import ../../../enums
import ../../../models/table
import ../../../models/column
import ../../query_util


# =============================================================================
# int
# =============================================================================
proc createSerialColumn(column:Column, table:Table):seq[string] =
  var query = &"ALTER TABLE \"{table.name}\" ADD COLUMN \"{column.name}\" SERIAL NOT NULL PRIMARY KEY"
  return @[query]


proc createIntColumn(column:Column, table:Table):seq[string] =
  var query = &"ALTER TABLE \"{table.name}\" ADD COLUMN \"{column.name}\" INTEGER"

  if column.isUnique:
    query.add(&" CONSTRAINT \"{table.name}_{column.name}_unique\" UNIQUE")

  if not column.isNullable:
    query.add(" NOT NULL")

  if column.isDefault:
    query.add(&" DEFAULT {column.defaultInt}")

  if column.isUnsigned:
    query.add(&" CHECK (\"{column.name}\" >= 0)")

  return @[query]


proc createSmallIntColumn(column:Column, table:Table):seq[string] =
  var query = &"ALTER TABLE \"{table.name}\" ADD COLUMN \"{column.name}\" SMALLINT"

  if column.isUnique:
    query.add(&" CONSTRAINT \"{table.name}_{column.name}_unique\" UNIQUE")

  if not column.isNullable:
    query.add(" NOT NULL")

  if column.isDefault:
    query.add(&" DEFAULT {column.defaultInt}")

  if column.isUnsigned:
    query.add(&" CHECK (\"{column.name}\" >= 0)")

  return @[query]


proc createMediumIntColumn(column:Column, table:Table):seq[string] =
  var query = &"ALTER TABLE \"{table.name}\" ADD COLUMN \"{column.name}\" INTEGER"

  if column.isUnique:
    query.add(&" CONSTRAINT \"{table.name}_{column.name}_unique\" UNIQUE")

  if not column.isNullable:
    query.add(" NOT NULL")

  if column.isDefault:
    query.add(&" DEFAULT {column.defaultInt}")

  if column.isUnsigned:
    query.add(&" CHECK (\"{column.name}\" >= 0)")

  return @[query]


proc createBigIntColumn(column:Column, table:Table):seq[string] =
  var query = &"ALTER TABLE \"{table.name}\" ADD COLUMN \"{column.name}\" BIGINT"

  if column.isUnique:
    query.add(&" CONSTRAINT \"{table.name}_{column.name}_unique\" UNIQUE")

  if not column.isNullable:
    query.add(" NOT NULL")

  if column.isDefault:
    query.add(&" DEFAULT {column.defaultInt}")

  if column.isUnsigned:
    query.add(&" CHECK (\"{column.name}\" >= 0)")

  return @[query]


# =============================================================================
# float
# =============================================================================
proc createDecimalColumn(column:Column, table:Table):seq[string] =
  let maximum = column.info["maximum"].getInt
  let digit = column.info["digit"].getInt
  var query = &"ALTER TABLE \"{table.name}\" ADD COLUMN \"{column.name}\" NUMERIC({maximum}, {digit})"

  if column.isUnique:
    query.add(&" CONSTRAINT \"{table.name}_{column.name}_unique\" UNIQUE")

  if not column.isNullable:
    query.add(" NOT NULL")

  if column.isDefault:
    query.add(&" DEFAULT {column.defaultFloat}")

  if column.isUnsigned:
    query.add(&" CHECK (\"{column.name}\" >= 0)")

  return @[query]


proc createFloatColumn(column:Column, table:Table):seq[string] =
  var query = &"ALTER TABLE \"{table.name}\" ADD COLUMN \"{column.name}\" NUMERIC"

  if column.isUnique:
    query.add(&" CONSTRAINT \"{table.name}_{column.name}_unique\" UNIQUE")

  if not column.isNullable:
    query.add(" NOT NULL")

  if column.isDefault:
    query.add(&" DEFAULT {column.defaultFloat}")

  if column.isUnsigned:
    query.add(&" CHECK (\"{column.name}\" >= 0)")

  return @[query]


# =============================================================================
# char
# =============================================================================
proc createCharColumn(column:Column, table:Table):seq[string] =
  let maxLength = column.info["maxLength"].getInt
  var query = &"ALTER TABLE \"{table.name}\" ADD COLUMN \"{column.name}\" CHAR({maxLength})"

  if column.isUnique:
    query.add(&" CONSTRAINT \"{table.name}_{column.name}_unique\" UNIQUE")

  if not column.isNullable:
    query.add(" NOT NULL")

  if column.isDefault:
    query.add(&" DEFAULT '{column.defaultString}'")

  if column.isUnsigned:
    notAllowedOption("unsigned", "char", column.name)

  return @[query]


proc createStringColumn(column:Column, table:Table):seq[string] =
  let maxLength = column.info["maxLength"].getInt
  var query = &"ALTER TABLE \"{table.name}\" ADD COLUMN \"{column.name}\" VARCHAR({maxLength})"

  if column.isUnique:
    query.add(&" CONSTRAINT \"{table.name}_{column.name}_unique\" UNIQUE")

  if not column.isNullable:
    query.add(" NOT NULL")

  if column.isDefault:
    query.add(&" DEFAULT '{column.defaultString}'")

  if column.isUnsigned:
    notAllowedOption("unsigned", "string", column.name)

  return @[query]


proc createTextColumn(column:Column, table:Table):seq[string] =
  var query = &"ALTER TABLE \"{table.name}\" ADD COLUMN \"{column.name}\" TEXT"

  if column.isUnique:
    query.add(&" CONSTRAINT \"{table.name}_{column.name}_unique\" UNIQUE")

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
proc createDateColumn(column:Column, table:Table):seq[string] =
  var query = &"ALTER TABLE \"{table.name}\" ADD COLUMN \"{column.name}\" DATE"

  if column.isUnique:
    query.add(&" CONSTRAINT \"{table.name}_{column.name}_unique\" UNIQUE")

  if not column.isNullable:
    query.add(" NOT NULL")

  if column.isDefault:
    query.add(&" DEFAULT (NOW())")

  if column.isUnsigned:
    notAllowedOption("unsigned", "date", column.name)

  return @[query]


proc createDatetimeColumn(column:Column, table:Table):seq[string] =
  var query = &"ALTER TABLE \"{table.name}\" ADD COLUMN \"{column.name}\" TIMESTAMP"

  if column.isUnique:
    query.add(&" CONSTRAINT \"{table.name}_{column.name}_unique\" UNIQUE")

  if not column.isNullable:
    query.add(" NOT NULL")

  if column.isDefault:
    query.add(&" DEFAULT (NOW())")

  if column.isUnsigned:
    notAllowedOption("unsigned", "date", column.name)

  return @[query]


proc createTimeColumn(column:Column, table:Table):seq[string] =
  var query = &"ALTER TABLE \"{table.name}\" ADD COLUMN \"{column.name}\" TIME"

  if column.isUnique:
    query.add(&" CONSTRAINT \"{table.name}_{column.name}_unique\" UNIQUE")

  if not column.isNullable:
    query.add(" NOT NULL")

  if column.isDefault:
    query.add(&" DEFAULT (NOW())")

  if column.isUnsigned:
    notAllowedOption("unsigned", "date", column.name)

  return @[query]


proc createTimestampColumn(column:Column, table:Table):seq[string] =
  var query = &"ALTER TABLE \"{table.name}\" ADD COLUMN \"{column.name}\" TIMESTAMP"

  if column.isUnique:
    query.add(&" CONSTRAINT \"{table.name}_{column.name}_unique\" UNIQUE")

  if not column.isNullable:
    query.add(" NOT NULL")

  if column.isDefault:
    query.add(&" DEFAULT (NOW())")

  if column.isUnsigned:
    notAllowedOption("unsigned", "date", column.name)

  return @[query]


proc createTimestampsColumn(column:Column, table:Table):seq[string] =
  var queries:seq[string] = @[]
  var query = &"ALTER TABLE \"{table.name}\" ADD COLUMN \"created_at\" TIMESTAMP"
  queries.add(query)
  query = &"ALTER TABLE \"{table.name}\" ADD COLUMN \"updated_at\" TIMESTAMP DEFAULT (NOW())"
  queries.add(query)
  return queries


proc createSoftDeleteColumn(column:Column, table:Table):seq[string] =
  let query = &"ALTER TABLE \"{table.name}\" ADD COLUMN \"deleted_at\" TIMESTAMP"
  return @[query]


# =============================================================================
# others
# =============================================================================
proc createBlobColumn(column:Column, table:Table):seq[string] =
  var query = &"ALTER TABLE \"{table.name}\" ADD COLUMN \"{column.name}\" BYTEA"

  if column.isUnique:
    query.add(&" CONSTRAINT \"{table.name}_{column.name}_unique\" UNIQUE")

  if not column.isNullable:
    query.add(" NOT NULL")

  if column.isDefault:
    query.add(&" DEFAULT '{column.defaultString}'")

  if column.isUnsigned:
    notAllowedOption("unsigned", "blob", column.name)

  return @[query]


proc createBoolColumn(column:Column, table:Table):seq[string] =
  var query = &"ALTER TABLE \"{table.name}\" ADD COLUMN \"{column.name}\" BOOLEAN"

  if column.isUnique:
    query.add(&" CONSTRAINT \"{table.name}_{column.name}_unique\" UNIQUE")

  if not column.isNullable:
    query.add(" NOT NULL")

  if column.isDefault:
    query.add(&" DEFAULT {column.defaultBool}")

  if column.isUnsigned:
    notAllowedOption("unsigned", "bool", column.name)

  return @[query]


proc enumOptionsGenerator(name:string, options:seq[string]):string =
  var optionsString = ""
  for i, option in options:
    if i > 0: optionsString.add(" OR ")
    optionsString.add(
      &"\"{name}\" = '{option}'"
    )

  return optionsString


proc createEnumColumn(column:Column, table:Table):seq[string] =
  var queries:seq[string]
  var query = &"ALTER TABLE \"{table.name}\" ADD COLUMN \"{column.name}\" CHARACTER"

  if column.isUnique:
    query.add(&" CONSTRAINT \"{table.name}_{column.name}_unique\" UNIQUE")

  if not column.isNullable:
    query.add(" NOT NULL")

  if column.isDefault:
    query.add(&" DEFAULT '{column.defaultString}'")
    
  if column.isUnsigned:
    notAllowedOption("unsigned", "text", column.name)

  var options:seq[string]
  for row in column.info["options"].items:
    options.add(row.getStr)

  let optionsString = enumOptionsGenerator(column.name, options)
  query.add(&" CHECK ({optionsString})")
  queries.add(query)

  return queries


proc createJsonColumn(column:Column, table:Table):seq[string] =
  var query = &"ALTER TABLE \"{table.name}\" ADD COLUMN \"{column.name}\" JSONB"

  if column.isUnique:
    query.add(&" CONSTRAINT \"{table.name}_{column.name}_unique\" UNIQUE")

  if column.isDefault:
    query.add(&" DEFAULT '{column.defaultJson.pretty}'")

  if column.isUnsigned:
    notAllowedOption("unsigned", "json", column.name)

  return @[query]


proc addForeignColumn(column:Column, table:Table):seq[string] =
  var query = &"ALTER TABLE \"{table.name}\" ADD COLUMN \"{column.name}\" INT"
  
  if column.isDefault:
    query.add(&" DEFAULT {column.defaultInt}")

  return @[query]


proc addStrForeignColumn(column:Column, table:Table):seq[string] =
  let maxLength = column.info["maxLength"].getInt
  var query = &"ALTER TABLE \"{table.name}\" ADD COLUMN \"{column.name}\" VARCHAR({maxLength})"

  if column.isDefault:
    query.add(&" DEFAULT '{column.defaultString}'")

  return @[query]


proc addForeignKey(column:Column, table:Table):string =
  var onDeleteString = "RESTRICT"
  if column.foreignOnDelete == CASCADE:
    onDeleteString = "CASCADE"
  elif column.foreignOnDelete == SET_NULL:
    onDeleteString = "SET NULL"
  elif column.foreignOnDelete == NO_ACTION:
    onDeleteString = "NO ACTION"

  let refColumn = column.info["column"].getStr
  let refTable = column.info["table"].getStr
  return &"ALTER TABLE \"{table.name}\" ADD FOREIGN KEY (\"{column.name}\") REFERENCES \"{refTable}\"(\"{refColumn}\") ON DELETE {onDeleteString}"


proc addIndexColumn(column:Column, table:Table):string =
  return &"CREATE INDEX IF NOT EXISTS \"{table.name}_{column.name}_index\" ON \"{table.name}\"(\"{column.name}\")"


proc addColumnString*(table:Table, column:Column) =
  case column.typ:
    # int
  of rdbIncrements:
    column.queries = column.createSerialColumn(table)
  of rdbInteger:
    column.queries = column.createIntColumn(table)
  of rdbSmallInteger:
    column.queries = column.createSmallIntColumn(table)
  of rdbMediumInteger:
    column.queries = column.createMediumIntColumn(table)
  of rdbBigInteger:
    column.queries = column.createBigIntColumn(table)
    # float
  of rdbDecimal:
    column.queries = column.createDecimalColumn(table)
  of rdbDouble:
    column.queries = column.createDecimalColumn(table)
  of rdbFloat:
    column.queries = column.createFloatColumn(table)
    # char
  of rdbUuid:
    column.queries = column.createStringColumn(table)
  of rdbChar:
    column.queries = column.createCharColumn(table)
  of rdbString:
    column.queries = column.createStringColumn(table)
    # text
  of rdbText:
    column.queries = column.createTextColumn(table)
  of rdbMediumText:
    column.queries = column.createTextColumn(table)
  of rdbLongText:
    column.queries = column.createTextColumn(table)
    # date
  of rdbDate:
    column.queries = column.createDateColumn(table)
  of rdbDatetime:
    column.queries = column.createDatetimeColumn(table)
  of rdbTime:
    column.queries = column.createTimeColumn(table)
  of rdbTimestamp:
    column.queries = column.createTimestampColumn(table)
  of rdbTimestamps:
    column.queries = column.createTimestampsColumn(table)
  of rdbSoftDelete:
    column.queries = column.createSoftDeleteColumn(table)
    # others
  of rdbBinary:
    column.queries = column.createBlobColumn(table)
  of rdbBoolean:
    column.queries = column.createBoolColumn(table)
  of rdbEnumField:
    column.queries = column.createEnumColumn(table)
  of rdbJson:
    column.queries = column.createJsonColumn(table)
  # foreign
  of rdbForeign:
    column.queries = column.addForeignColumn(table)
    column.queries.add(column.addForeignKey(table))
  of rdbStrForeign:
    column.queries = column.addStrForeignColumn(table)
    column.queries.add(column.addForeignKey(table))

  if column.isIndex:
    column.queries.add(column.addIndexColumn(table))
