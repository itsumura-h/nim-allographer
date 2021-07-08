import json


type
  Column* = ref object
    name*: string
    typ*: RdbTypekind
    isIndex*: bool
    isNullable*: bool
    isUnsigned*: bool
    isDefault*: bool
    isUnique*: bool
    defaultBool*: bool
    defaultInt*: int
    defaultFloat*: float
    defaultString*: string
    defaultJson*: JsonNode
    foreignOnDelete*: ForeignOnDelete
    info*: JsonNode
    # alter table
    alterTyp*:AlterTyp
    previousName*:string

  AlterTyp* = enum
    Add
    Change
    Delete

  RdbTypekind* = enum
    # int
    rdbIncrements = "rdbIncrements"
    rdbInteger = "rdbInteger"
    rdbSmallInteger = "rdbSmallInteger"
    rdbMediumInteger = "rdbMediumInteger"
    rdbBigInteger = "rdbBigInteger"
    # float
    rdbDecimal = "rdbDecimal"
    rdbDouble = "rdbDouble"
    rdbFloat = "rdbFloat"
    # char
    rdbChar = "rdbChar"
    rdbString = "rdbString"
    # text
    rdbText = "rdbText"
    rdbMediumText = "rdbMediumText"
    rdbLongText = "rdbLongText"
    # date
    rdbDate = "rdbDate"
    rdbDatetime = "rdbDatetime"
    rdbTime = "rdbTime"
    rdbTimestamp = "rdbTimestamp"
    rdbTimestamps = "rdbTimestamps"
    rdbSoftDelete = "rdbSoftDelete"
    # others
    rdbBinary = "rdbBinary"
    rdbBoolean = "rdbBoolean"
    rdbEnumField = "rdbEnumField"
    rdbJson = "rdbJson"
    rdbForeign = "rdbForeign"

  ForeignOnDelete* = enum
    RESTRICT = "RESTRICT"
    CASCADE = "CASCADE"
    SET_NULL = "SET_NULL"
    NO_ACTION = "NO_ACTION"


proc default*(c: Column, value:bool): Column =
  c.isDefault = true
  c.defaultBool = value
  return c

proc default*(c: Column, value:int): Column =
  c.isDefault = true
  c.defaultInt = value
  return c

proc default*(c: Column, value:float): Column =
  c.isDefault = true
  c.defaultFloat = value
  return c

proc default*(c: Column, value:string): Column =
  c.isDefault = true
  c.defaultString = value
  return c

proc default*(c: Column, value:JsonNode): Column =
  c.isDefault = true
  c.defaultJson = value
  return c

proc default*(c:Column):Column =
  c.isDefault = true
  return c

proc index*(c:Column):Column =
  c.isIndex = true
  return c

proc nullable*(c: Column): Column =
  c.isNullable = true
  return c

proc unique*(c:Column): Column =
  c.isUnique = true
  return c

proc unsigned*(c: Column): Column =
  c.isUnsigned = true
  return c


# =============================================================================
# int
# =============================================================================
proc increments*(self:Column, name:string): Column =
  self.name = name
  self.typ = rdbIncrements
  return self

proc integer*(self:Column, name:string):Column =
  self.name = name
  self.typ = rdbInteger
  return self

proc smallInteger*(self:Column, name:string):Column =
  self.name = name
  self.typ = rdbSmallInteger
  return self

proc mediumInteger*(self:Column, name:string):Column =
  self.name = name
  self.typ = rdbMediumInteger
  return self

proc bigInteger*(self:Column, name:string):Column =
  self.name = name
  self.typ = rdbBigInteger
  return self

# =============================================================================
# float
# =============================================================================
proc decimal*(self:Column, name:string, maximum:int, digit:int): Column =
  self.name = name
  self.typ = rdbDecimal
  self.info = %*{
    "maximum": maximum,
    "digit": digit
  }
  return self

proc double*(self:Column, name:string, maximum:int, digit:int):Column =
  self.name = name
  self.typ = rdbDouble
  self.info = %*{
    "maximum": maximum,
    "digit": digit
  }
  return self

proc float*(self:Column, name:string):Column =
  self.name = name
  self.typ = rdbFloat
  return self

# =============================================================================
# char
# =============================================================================
proc char*(self:Column, name:string, maxLength:int): Column =
  self.name = name
  self.typ = rdbChar
  self.info = %*{
    "maxLength": maxLength
  }
  return self

proc string*(self:Column, name:string, length=255):Column =
  self.name = name
  self.typ = rdbString
  self.info = %*{"maxLength": length}
  return self

proc text*(self:Column, name:string):Column =
  self.name = name
  self.typ = rdbText
  return self

proc mediumText*(self:Column, name:string):Column =
  self.name = name
  self.typ = rdbMediumText
  return self

proc longText*(self:Column, name:string):Column =
  self.name = name
  self.typ = rdbLongText
  return self

# =============================================================================
# date
# =============================================================================
proc date*(self:Column, name:string):Column =
  self.name = name
  self.typ = rdbDate
  return self

proc datetime*(self:Column, name:string):Column =
  self.name = name
  self.typ = rdbDatetime
  return self

proc time*(self:Column, name:string):Column =
  self.name = name
  self.typ = rdbTime
  return self

proc timestamp*(self:Column, name:string):Column =
  self.name = name
  self.typ = rdbTimestamp
  return self

proc timestamps*(self:Column):Column =
  self.typ = rdbTimestamps
  return self

proc softDelete*(self:Column):Column =
  self.typ = rdbSoftDelete
  return self

# =============================================================================
# others
# =============================================================================
proc binary*(self:Column, name:string): Column =
  self.name = name
  self.typ = rdbBinary
  return self

# =============================================================================
proc boolean*(self:Column, name:string): Column =
  self.name = name
  self.typ = rdbBoolean
  return self

proc enumField*(self:Column, name:string, options:openArray[string]):Column =
  self.name = name
  self.typ = rdbEnumField
  self.info = %*{
    "options": options
  }
  return self

proc json*(self:Column, name:string):Column =
  self.name = name
  self.typ = rdbJson
  return self

# =============================================================================
# Foreign
# =============================================================================
proc foreign*(self:Column, name:string):Column =
  self.name = name
  self.typ = rdbForeign
  return self

proc reference*(self:Column, column:string):Column =
  self.info = %*{
    "column": column
  }
  return self

proc on*(self:Column, table:string):Column =
  self.info["table"] = %*table
  return self

proc onDelete*(self:Column, kind:ForeignOnDelete):Column =
  self.foreignOnDelete = kind
  return self
