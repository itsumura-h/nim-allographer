import db_common, json
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
    name: name,
    typ: dbSerial,
    isNullable: false,
    isUnsigned: true
  )

proc integer*(this:Schema, name:string):Column =
  Column(
    name: name,
    typ: dbInt,
    info: %*{
      "size": "normal"
    }
  )

proc smallInteger*(this:Schema, name:string):Column =
  Column(
    name: name,
    typ: dbInt,
    info: %*{
      "size": "small"
    }
  )

proc mediumInteger*(this:Schema, name:string):Column =
  Column(
    name: name,
    typ: dbInt,
    info: %*{
      "size": "medium"
    }
  )

proc bigInteger*(this:Schema, name:string):Column =
  Column(
    name: name,
    typ: dbInt,
    info: %*{
      "size": "big"
    }
  )

# =============================================================================
# float
# =============================================================================
proc decimal*(this:Schema, name:string, maximum:int, digit:int): Column =
  Column(
    name: name,
    typ: dbDecimal,
    info: %*{
      "maximum": maximum,
      "digit": digit
    }
  )

proc double*(this:Schema, name:string, maximum:int, digit:int):Column =
  Column(
    name: name,
    typ: dbFloat,
    info: %*{
      "maximum": maximum,
      "digit": digit
    }
  )

proc float*(this:Schema, name:string):Column =
  Column(
    name: name,
    typ: dbFloat
  )

# =============================================================================
# char
# =============================================================================
proc char*(this:Schema, name:string, maxLength:int): Column =
  Column(
    name: name,
    typ: dbFixedChar,
    info: %*{
      "maxLength": maxLength
    }
  )

proc string*(this:Schema, name:string, length=255):Column =
  Column(
    name: name,
    typ: dbVarchar,
    info: %*{
      "maxLength": length
    }
  )

proc text*(this:Schema, name:string):Column =
  Column(
    name: name,
    typ: dbXml,
    info: %*{
      "size": "normal"
    }
  )

proc mediumText*(this:Schema, name:string):Column =
  Column(
    name: name,
    typ: dbXml,
    info: %*{
      "size": "medium"
    }
  )

proc longText*(this:Schema, name:string):Column =
  Column(
    name: name,
    typ: dbXml,
    info: %*{
      "size": "long"
    }
  )

# =============================================================================
# date
# =============================================================================
proc date*(this:Schema, name:string):Column =
  Column(
    name: name,
    typ: dbDate
  )

proc datetime*(this:Schema, name:string):Column =
  Column(
    name: name,
    typ: dbDatetime
  )

proc time*(this:Schema, name:string):Column =
  Column(
    name: name,
    typ: dbTime
  )

proc timestamp*(this:Schema, name:string):Column =
  Column(
    name: name,
    typ: dbTimestamp,
    info: %*{
      "status": "timestamp"
    }
  )

proc timestamps*(this:Schema):Column =
  Column(
    typ: dbTimestamp,
    info: %*{
      "status": "timestamps"
    }
  )

proc softDeletes*(this:Schema):Column =
  Column(
    typ: dbTimestamp,
    info: %*{
      "status": "softDeletes"
    }
  )

# =============================================================================
# others
# =============================================================================
proc binary*(this:Schema, name:string): Column =
  Column(
    name: name,
    typ: dbBlob
  )

# =============================================================================
proc boolean*(this:Schema, name:string): Column =
  Column(
    name: name,
    typ: dbBool
  )

proc enumField*(this:Schema, name:string, options:varargs[string]):Column =
  Column(
    name: name,
    typ: dbEnum,
    info: %*{
      "options": options
    }
  )

proc json*(this:Schema, name:string):Column =
  Column(
    name: name,
    typ: dbJson
  )
