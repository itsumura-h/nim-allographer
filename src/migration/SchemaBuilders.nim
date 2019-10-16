import json
import db_common, model

type Schema* = ref object

proc nullable*(cArg: Column): Column =
  var c = cArg
  c.isNullable = true
  echo repr c
  return c

proc unsigned*(c: Column): Column =
  c.isUnsigned = true
  return c

export
  nullable,
  unsigned

# =======================================================

proc bigIncrements*(this: Schema, name:string): Column =
  Column(
    name: name,
    typ: dbSerial,
    isNullable: false,
    isUnsigned: true
  )

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

proc binary*(this: Schema, name:string): Column =
  Column(
    name: name,
    typ: dbBlob
  )

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

# proc char*(this: Schema, name:string, maxLength:int, nullable=false,
#             default="default_value"): Column =
#   Column(
#     name: name,
#     typ: dbFixedChar,
#     nullable: nullable,
#     default: default,
#     info: %*{
#       "maxLength": maxLength
#     }
#   )

# proc date*(this: Schema, name:string, nullable=false): Column =
#   Column(
#     name: name,
#     typ: dbDate,
#     nullable: nullable
#   )

# proc datetime*(this: Schema, name: string, nullable=false): DbColumn =
#   DbColumn(
#     name: name,
#     typ: DbType(kind: dbDatetime, notNull: not nullable)
#   )
