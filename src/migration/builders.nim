import json
import base

type Schema* = ref object


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

proc default*(cArg:Column):Column =
  var c = cArg
  c.isDefault = true
  return c

proc nullable*(cArg: Column): Column =
  var c = cArg
  c.isNullable = true
  return c

proc unsigned*(c: Column): Column =
  c.isUnsigned = true
  return c

# =============================================================================
# int
# =============================================================================
proc increments*(this:Schema, name:string): Column =
  Column(
    name: name
  )

proc integer*(this:Schema, name:string):Column =
  Column(
    name: name,
    typ: rdbInteger
  )

proc smallInteger*(this:Schema, name:string):Column =
  Column(
    name: name,
    typ: rdbSmallInteger,
  )

proc mediumInteger*(this:Schema, name:string):Column =
  Column(
    name: name,
    typ: rdbMediumInteger
  )

proc bigInteger*(this:Schema, name:string):Column =
  Column(
    name: name,
    typ: rdbBigInteger
  )

# =============================================================================
# float
# =============================================================================
proc decimal*(this:Schema, name:string, maximum:int, digit:int): Column =
  Column(
    name: name,
    typ: rdbDecimal,
    info: %*{
      "maximum": maximum,
      "digit": digit
    }
  )

proc double*(this:Schema, name:string, maximum:int, digit:int):Column =
  Column(
    name: name,
    typ: rdbDouble,
    info: %*{
      "maximum": maximum,
      "digit": digit
    }
  )

proc float*(this:Schema, name:string):Column =
  Column(
    name: name,
    typ: rdbFloat
  )

# =============================================================================
# char
# =============================================================================
proc char*(this:Schema, name:string, maxLength:int): Column =
  Column(
    name: name,
    typ: rdbChar,
    info: %*{
      "maxLength": maxLength
    }
  )

proc string*(this:Schema, name:string, length=255):Column =
  Column(
    name: name,
    typ: rdbString,
    info: %*{
      "maxLength": length
    }
  )

proc text*(this:Schema, name:string):Column =
  Column(
    name: name,
    typ: rdbText
  )

proc mediumText*(this:Schema, name:string):Column =
  Column(
    name: name,
    typ: rdbMediumText
  )

proc longText*(this:Schema, name:string):Column =
  Column(
    name: name,
    typ: rdbLongText
  )

# =============================================================================
# date
# =============================================================================
proc date*(this:Schema, name:string):Column =
  Column(
    name: name,
    typ: rdbDate
  )

proc datetime*(this:Schema, name:string):Column =
  Column(
    name: name,
    typ: rdbDatetime
  )

proc time*(this:Schema, name:string):Column =
  Column(
    name: name,
    typ: rdbTime
  )

proc timestamp*(this:Schema, name:string):Column =
  Column(
    name: name,
    typ: rdbTimestamp
  )

proc timestamps*(this:Schema):Column =
  Column(
    typ: rdbTimestamps
  )

proc softDelete*(this:Schema):Column =
  Column(
    typ: rdbSoftDelete
  )

# =============================================================================
# others
# =============================================================================
proc binary*(this:Schema, name:string): Column =
  Column(
    name: name,
    typ: rdbBinary
  )

# =============================================================================
proc boolean*(this:Schema, name:string): Column =
  Column(
    name: name,
    typ: rdbBoolean
  )

proc enumField*(this:Schema, name:string, options:varargs[string]):Column =
  Column(
    name: name,
    typ: rdbEnumField,
    info: %*{
      "options": options
    }
  )

proc json*(this:Schema, name:string):Column =
  Column(
    name: name,
    typ: rdbJson
  )

# =============================================================================
# Foreign
# =============================================================================
proc foreign*(this:Schema, name:string):Column =
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
