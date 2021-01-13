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
proc increments*(this:Column, name:string): Column =
  this.name = name
  this.typ = rdbIncrements
  return this

proc integer*(this:Column, name:string):Column =
  this.name = name
  this.typ = rdbInteger
  return this

proc smallInteger*(this:Column, name:string):Column =
  this.name = name
  this.typ = rdbSmallInteger
  return this

proc mediumInteger*(this:Column, name:string):Column =
  this.name = name
  this.typ = rdbMediumInteger
  return this

proc bigInteger*(this:Column, name:string):Column =
  this.name = name
  this.typ = rdbBigInteger
  return this

# =============================================================================
# float
# =============================================================================
proc decimal*(this:Column, name:string, maximum:int, digit:int): Column =
  this.name = name
  this.typ = rdbDecimal
  this.info = %*{
    "maximum": maximum,
    "digit": digit
  }
  return this

proc double*(this:Column, name:string, maximum:int, digit:int):Column =
  this.name = name
  this.typ = rdbDouble
  this.info = %*{
    "maximum": maximum,
    "digit": digit
  }
  return this

proc float*(this:Column, name:string):Column =
  this.name = name
  this.typ = rdbFloat
  return this

# =============================================================================
# char
# =============================================================================
proc char*(this:Column, name:string, maxLength:int): Column =
  this.name = name
  this.typ = rdbChar
  this.info = %*{
    "maxLength": maxLength
  }
  return this

proc string*(this:Column, name:string, length=255):Column =
  this.name = name
  this.typ = rdbString
  this.info = %*{"maxLength": length}
  return this

proc text*(this:Column, name:string):Column =
  this.name = name
  this.typ = rdbText
  return this

proc mediumText*(this:Column, name:string):Column =
  this.name = name
  this.typ = rdbMediumText
  return this

proc longText*(this:Column, name:string):Column =
  this.name = name
  this.typ = rdbLongText
  return this

# =============================================================================
# date
# =============================================================================
proc date*(this:Column, name:string):Column =
  this.name = name
  this.typ = rdbDate
  return this

proc datetime*(this:Column, name:string):Column =
  this.name = name
  this.typ = rdbDatetime
  return this

proc time*(this:Column, name:string):Column =
  this.name = name
  this.typ = rdbTime
  return this

proc timestamp*(this:Column, name:string):Column =
  this.name = name
  this.typ = rdbTimestamp
  return this

proc timestamps*(this:Column):Column =
  this.typ = rdbTimestamps
  return this

proc softDelete*(this:Column):Column =
  this.typ = rdbSoftDelete
  return this

# =============================================================================
# others
# =============================================================================
proc binary*(this:Column, name:string): Column =
  this.name = name
  this.typ = rdbBinary
  return this

# =============================================================================
proc boolean*(this:Column, name:string): Column =
  this.name = name
  this.typ = rdbBoolean
  return this

proc enumField*(this:Column, name:string, options:openArray[string]):Column =
  this.name = name
  this.typ = rdbEnumField
  this.info = %*{
    "options": options
  }
  return this

proc json*(this:Column, name:string):Column =
  this.name = name
  this.typ = rdbJson
  return this

# =============================================================================
# Foreign
# =============================================================================
proc foreign*(this:Column, name:string):Column =
  this.name = name
  this.typ = rdbForeign
  return this

proc reference*(this:Column, column:string):Column =
  this.info = %*{
    "column": column
  }
  return this

proc on*(this:Column, table:string):Column =
  this.info["table"] = %*table
  return this

proc onDelete*(this:Column, kind:ForeignOnDelete):Column =
  this.foreignOnDelete = kind
  return this
