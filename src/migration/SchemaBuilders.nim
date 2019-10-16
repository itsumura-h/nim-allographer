import json
import db_common, model

type Schema* = ref object

proc nullable*(cArg: Column): Column =
  var c = cArg
  c.isNullable = true
  return c

proc unsigned*(c: Column): Column =
  c.isUnsigned = true
  return c


# =============================================================================
proc bigIncrements*(this: Schema, name:string): Column =
  Column(
    name: name,
    typ: dbSerial,
    isNullable: false,
    isUnsigned: true
  )

# =============================================================================
proc bigInteger*(this: Schema, name:string): Column =
  Column(
    name: name,
    typ:dbInt
  )

proc bigInteger*(this: Schema, name:string, default:int): Column =
  Column(
    name: name,
    typ: dbInt,
    isDefault: true,
    defaultInt: default
  )

# =============================================================================
proc binary*(this: Schema, name:string): Column =
  Column(
    name: name,
    typ: dbBlob
  )

# =============================================================================
proc boolean*(this: Schema, name:string): Column =
  Column(
    name: name,
    typ: dbBool
  )

proc boolean*(this: Schema, name:string, default:bool): Column =
  Column(
    name: name,
    typ: dbBool,
    isDefault: true,
    defaultBool: default
  )

# =============================================================================
proc char*(this: Schema, name:string, maxLength:int): Column =
  Column(
    name: name,
    typ: dbFixedChar,
    info: %*{
    "maxLength": maxLength
    }
  )

proc char*(this: Schema, name:string, maxLength:int, default:string): Column =
  Column(
    name: name,
    typ: dbFixedChar,
    isDefault: true,
    defaultString: default,
    info: %*{
      "maxLength": maxLength
    }
  )

# =============================================================================
proc date*(this: Schema, name:string): Column =
  Column(
    name: name,
    typ: dbDate
  )

# =============================================================================
proc datetime*(this: Schema, name: string): Column =
  Column(
    name: name,
    typ: dbDatetime
  )
