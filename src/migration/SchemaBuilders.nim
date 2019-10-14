import json
import db_common, model

type Schema* = ref object


proc bigIncrements*(this: Schema, name:string): Column =
  Column(
    name: name,
    typ: dbSerial,
    nullable: false
  )

proc bigInteger*(this: Schema, name:string, nullable=false,
                  default="default_value"): Column =
  Column(
    name: name,
    typ:dbInt,
    nullable: nullable,
    default: default
  )

proc binary*(this: Schema, name:string, nullable=false): Column =
  Column(
    name: name,
    typ: dbBlob,
    nullable: nullable
  )

proc boolean*(this: Schema, name:string, nullable=false, 
              default="default_value"): Column =
  Column(
    name: name,
    typ: dbBool,
    nullable: nullable,
    default: default
  )

proc char*(this: Schema, name:string, maxLength:int, nullable=false,
            default="default null"): Column =
  Column(
    name: name,
    typ: dbFixedChar,
    nullable: nullable,
    default: default,
    info: %*{
      "maxLength": maxLength
    }
  )

proc date*(this: Schema, name:string, nullable=false): DbColumn =
  DbColumn(
    name: name,
    typ: DbType(kind: dbDate, notNull: not nullable)
  )

proc datetime*(this: Schema, name: string, nullable=false): DbColumn =
  DbColumn(
    name: name,
    typ: DbType(kind: dbDatetime, notNull: not nullable)
  )
