import json


type
  Column* = ref object
    name*: string
    typ*: RdbTypekind
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


proc default*(cArg: Column, value:bool): Column =
  var c = cArg
  c.isDefault = true
  c.defaultBool = value
  return c

proc default*(cArg: Column, value:int): Column =
  var c = cArg
  c.isDefault = true
  c.defaultInt = value
  return c

proc default*(cArg: Column, value:float): Column =
  var c = cArg
  c.isDefault = true
  c.defaultFloat = value
  return c

proc default*(cArg: Column, value:string): Column =
  var c = cArg
  c.isDefault = true
  c.defaultString = value
  return c

proc default*(cArg: Column, value:JsonNode): Column =
  var c = cArg
  c.isDefault = true
  c.defaultJson = value
  return c

proc default*(cArg:Column):Column =
  var c = cArg
  c.isDefault = true
  return c

proc nullable*(cArg: Column): Column =
  var c = cArg
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
  Column(
    name: name,
    typ: rdbIncrements
  )

proc integer*(this:Column, name:string):Column =
  Column(
    name: name,
    typ: rdbInteger
  )

proc smallInteger*(this:Column, name:string):Column =
  Column(
    name: name,
    typ: rdbSmallInteger,
  )

proc mediumInteger*(this:Column, name:string):Column =
  Column(
    name: name,
    typ: rdbMediumInteger
  )

proc bigInteger*(this:Column, name:string):Column =
  Column(
    name: name,
    typ: rdbBigInteger
  )

# =============================================================================
# float
# =============================================================================
proc decimal*(this:Column, name:string, maximum:int, digit:int): Column =
  Column(
    name: name,
    typ: rdbDecimal,
    info: %*{
      "maximum": maximum,
      "digit": digit
    }
  )

proc double*(this:Column, name:string, maximum:int, digit:int):Column =
  Column(
    name: name,
    typ: rdbDouble,
    info: %*{
      "maximum": maximum,
      "digit": digit
    }
  )

proc float*(this:Column, name:string):Column =
  Column(
    name: name,
    typ: rdbFloat
  )

# =============================================================================
# char
# =============================================================================
proc char*(this:Column, name:string, maxLength:int): Column =
  Column(
    name: name,
    typ: rdbChar,
    info: %*{
      "maxLength": maxLength
    }
  )

proc string*(this:Column, name:string, length=255):Column =
  # Column(
  #   name: name,
  #   typ: rdbString,
  #   info: %*{
  #     "maxLength": length
  #   }
  # )
  this.name = name
  this.typ = rdbString
  this.info = %*{"maxLength": length}
  return this

proc text*(this:Column, name:string):Column =
  Column(
    name: name,
    typ: rdbText
  )

proc mediumText*(this:Column, name:string):Column =
  Column(
    name: name,
    typ: rdbMediumText
  )

proc longText*(this:Column, name:string):Column =
  Column(
    name: name,
    typ: rdbLongText
  )

# =============================================================================
# date
# =============================================================================
proc date*(this:Column, name:string):Column =
  Column(
    name: name,
    typ: rdbDate
  )

proc datetime*(this:Column, name:string):Column =
  Column(
    name: name,
    typ: rdbDatetime
  )

proc time*(this:Column, name:string):Column =
  Column(
    name: name,
    typ: rdbTime
  )

proc timestamp*(this:Column, name:string):Column =
  Column(
    name: name,
    typ: rdbTimestamp
  )

proc timestamps*(this:Column):Column =
  Column(
    typ: rdbTimestamps
  )

proc softDelete*(this:Column):Column =
  Column(
    typ: rdbSoftDelete
  )

# =============================================================================
# others
# =============================================================================
proc binary*(this:Column, name:string): Column =
  Column(
    name: name,
    typ: rdbBinary
  )

# =============================================================================
proc boolean*(this:Column, name:string): Column =
  Column(
    name: name,
    typ: rdbBoolean
  )

proc enumField*(this:Column, name:string, options:openArray[string]):Column =
  Column(
    name: name,
    typ: rdbEnumField,
    info: %*{
      "options": options
    }
  )

proc json*(this:Column, name:string):Column =
  Column(
    name: name,
    typ: rdbJson
  )

# =============================================================================
# Foreign
# =============================================================================
proc foreign*(this:Column, name:string):Column =
  Column(
    name: name,
    typ: rdbForeign
  )

proc reference*(this:Column, column:string):Column =
  var c = this
  c.info = %*{
    "column": column
  }
  return c

proc on*(this:Column, table:string):Column =
  var c = this
  c.info["table"] = %*table
  return c

proc onDelete*(this:Column, kind:ForeignOnDelete):Column =
  var c = this
  c.foreignOnDelete = kind
  return c
