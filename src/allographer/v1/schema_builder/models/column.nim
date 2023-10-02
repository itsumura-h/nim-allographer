import std/json
import ../enums


type Column* = ref object
  name*: string
  typ*: RdbTypeKind
  isIndex*: bool
  isNullable*: bool
  isUnsigned*: bool
  isUnique*: bool
  isAutoIncrement*:bool
  isDefault*: bool
  defaultBool*: bool
  defaultInt*: int
  defaultFloat*: float
  defaultString*: string
  defaultJson*: JsonNode
  defaultDatetime*: DefaultDateTime
  foreignOnDelete*: ForeignOnDelete
  info*: JsonNode
  checksum*:string
  # alter table
  previousName*:string
  migrationType*:ColumnMigrationType
  usecaseType*:UsecaseType

proc new(_:type Column):Column =
  return Column(
    defaultJson: newJNull(),
    info: newJNull(),
  )

proc toSchema*(self:Column):JsonNode =
  return %*{
    "name": self.name,
    "typ": self.typ,
    "isIndex": self.isIndex,
    "isNullable": self.isNullable,
    "isUnsigned": self.isUnsigned,
    "isUnique": self.isUnique,
    "isAutoIncrement": self.isAutoIncrement,
    "isDefault": self.isDefault,
    "defaultBool": self.defaultBool,
    "defaultInt": self.defaultInt,
    "defaultFloat": self.defaultFloat,
    "defaultString": self.defaultString,
    "defaultJson": self.defaultJson,
    "foreignOnDelete": self.foreignOnDelete,
    "info": self.info,
    "previousName":self.previousName,
    "migrationType":self.migrationType,
    "usecaseType": self.usecaseType
  }

# =============================================================================
# int
# =============================================================================
proc increments*(_:type Column, name:string): Column =
  let column = Column.new()
  column.name = name
  column.typ = rdbIncrements
  return column


proc integer*(_:type Column, name:string):Column =
  let column = Column.new()
  column.name = name
  column.typ = rdbInteger
  return column


proc smallInteger*(_:type Column, name:string):Column =
  let column = Column.new()
  column.name = name
  column.typ = rdbSmallInteger
  return column


proc mediumInteger*(_:type Column, name:string):Column =
  let column = Column.new()
  column.name = name
  column.typ = rdbMediumInteger
  return column


proc bigInteger*(_:type Column, name:string):Column =
  let column = Column.new()
  column.name = name
  column.typ = rdbBigInteger
  return column


# =============================================================================
# float
# =============================================================================
proc decimal*(_:type Column, name:string, maximum:int, digit:int): Column =
  let column = Column.new()
  column.name = name
  column.typ = rdbDecimal
  column.info = %*{
    "maximum": maximum,
    "digit": digit
  }
  return column


proc double*(_:type Column, name:string, maximum:int, digit:int):Column =
  let column = Column.new()
  column.name = name
  column.typ = rdbDouble
  column.info = %*{
    "maximum": maximum,
    "digit": digit
  }
  return column


proc float*(_:type Column, name:string):Column =
  let column = Column.new()
  column.name = name
  column.typ = rdbFloat
  return column


# =============================================================================
# char
# =============================================================================
proc char*(_:type Column, name:string, maxLength:int): Column =
  let column = Column.new()
  column.name = name
  column.typ = rdbChar
  column.info = %*{
    "maxLength": maxLength
  }
  return column


proc string*(_:type Column, name:string, length=255):Column =
  let column = Column.new()
  column.name = name
  column.typ = rdbString
  column.info = %*{"maxLength": length}
  return column


proc uuid*(_:type Column, name:string):Column =
  let column = Column.new()
  column.name = name
  column.typ = rdbUuid
  column.isUnique = true
  column.info = %*{"maxLength": 255}
  return column


proc text*(_:type Column, name:string):Column =
  let column = Column.new()
  column.name = name
  column.typ = rdbText
  return column


proc mediumText*(_:type Column, name:string):Column =
  let column = Column.new()
  column.name = name
  column.typ = rdbMediumText
  return column


proc longText*(_:type Column, name:string):Column =
  let column = Column.new()
  column.name = name
  column.typ = rdbLongText
  return column


# =============================================================================
# date
# =============================================================================
proc date*(_:type Column, name:string):Column =
  let column = Column.new()
  column.name = name
  column.typ = rdbDate
  return column


proc datetime*(_:type Column, name:string):Column =
  let column = Column.new()
  column.name = name
  column.typ = rdbDatetime
  return column


proc time*(_:type Column, name:string):Column =
  let column = Column.new()
  column.name = name
  column.typ = rdbTime
  return column


proc timestamp*(_:type Column, name:string):Column =
  let column = Column.new()
  column.name = name
  column.typ = rdbTimestamp
  return column


proc timestamps*(_:type Column):Column =
  let column = Column.new()
  column.typ = rdbTimestamps
  return column


proc softDelete*(_:type Column):Column =
  let column = Column.new()
  column.typ = rdbSoftDelete
  return column


# =============================================================================
# others
# =============================================================================
proc binary*(_:type Column, name:string): Column =
  let column = Column.new()
  column.name = name
  column.typ = rdbBinary
  return column


proc boolean*(_:type Column, name:string): Column =
  let column = Column.new()
  column.name = name
  column.typ = rdbBoolean
  return column


proc enumField*(_:type Column, name:string, options:openArray[string]):Column =
  let column = Column.new()
  column.name = name
  column.typ = rdbEnumField
  column.info = %*{
    "options": options
  }
  return column


proc json*(_:type Column, name:string):Column =
  let column = Column.new()
  column.name = name
  column.typ = rdbJson
  return column


# =============================================================================
# Foreign
# =============================================================================
proc foreign*(_:type Column, name:string):Column =
  let column = Column.new()
  column.name = name
  column.previousName = name
  column.typ = rdbForeign
  column.isIndex = false
  return column


proc strForeign*(_:type Column, name:string, length=255):Column =
  let column = Column.new()
  column.name = name
  column.previousName = name
  column.typ = rdbStrForeign
  column.isIndex = false
  column.info = %*{"maxLength": length}
  return column


proc reference*(self:Column, column:string):Column =
  if self.info.kind == JNull:
    self.info = %*{"column": column}
  else:
    self.info["column"] = %column
  return self


proc on*(self:Column, table:string):Column {.deprecated: "Use `onTable` instead after Nim v2".} =
  self.info["table"] = %*table
  return self


proc onDelete*(self:Column, kind:ForeignOnDelete):Column =
  self.foreignOnDelete = kind
  return self


# =============================================================================
# options
# =============================================================================
proc autoIncrement*(c: Column): Column =
  c.isAutoIncrement = true
  c.isDefault = false
  c.isUnique = true
  return c


proc default*(c: Column, value:bool): Column =
  if not c.isAutoIncrement:
    c.isDefault = true
    c.defaultBool = value
  return c


proc default*(c: Column, value:int): Column =
  if not c.isAutoIncrement:
    c.isDefault = true
    c.defaultInt = value
  return c


proc default*(c: Column, value:float): Column =
  if not c.isAutoIncrement:
    c.isDefault = true
    c.defaultFloat = value
  return c


proc default*(c: Column, value:string): Column =
  if not c.isAutoIncrement:
    c.isDefault = true
    c.defaultString = value
  return c


proc default*(c: Column, value:JsonNode): Column =
  if not c.isAutoIncrement:
    c.isDefault = true
    c.defaultJson = value
  return c


proc default*(c: Column, value:DefaultDateTime): Column =
  if not c.isAutoIncrement:
    c.isDefault = true
    c.defaultDatetime = value
  return c


proc default*(c: Column):Column =
  if not c.isAutoIncrement:
    c.isDefault = true
  return c


proc index*(c: Column):Column =
  if not c.isUnique:
    c.isIndex = true
  return c


proc nullable*(c: Column): Column =
  c.isNullable = true
  return c


proc unique*(c: Column): Column =
  c.isUnique = true
  c.isIndex = false
  return c


proc unsigned*(c: Column): Column =
  c.isUnsigned = true
  return c


# =============================================================================
# alter table
# =============================================================================
proc add*(c: Column): Column =
  c.migrationType = AddColumn
  return c

proc change*(c: Column): Column =
  c.migrationType = ChangeColumn
  return c

proc renameColumn*(_:type Column, src, dest:string): Column =
  let column = Column.new()
  column.name = dest  
  column.previousName = src
  column.migrationType = RenameColumn
  return column

proc dropColumn*(_:type Column, name:string): Column =
  let column = Column.new()
  column.name = name
  column.migrationType = DropColumn
  return column
