import db_common

type Schema* = ref object of RootObj


proc bigIncrements*(this: Schema, name:string): DbColumn =
  DbColumn(
    name: name,
    typ: DbType(kind: dbSerial, notNull:true)
  )

proc bigInteger*(this: Schema, name:string, notNull=true): DbColumn =
  DbColumn(
    name: name,
    typ: DbType(kind: dbInt, notNull: notNull)
  )

proc binary*(this: Schema, name:string, notNull=true): DbColumn =
  DbColumn(
    name: name,
    typ: DbType(kind: dbBlob, notNull: notNull)
  )

proc boolean*(this: Schema, name:string, notNull=true): DbColumn =
  DbColumn(
    name: name,
    typ: DbType(kind: dbBool, notNull: notNull)
  )

proc char*(this: Schema, name:string, maxReprLen:int, notNull=true,
            default="default null"): DbColumn =
  if default == "default null":
    DbColumn(
      name: name,
      typ: DbType(
        kind: dbFixedChar,
        maxReprLen: maxReprLen,
        notNull: notNull
      ),
    )
  else:
    DbColumn(
      name: name,
      typ: DbType(
        kind: dbFixedChar,
        maxReprLen: maxReprLen,
        notNull: notNull,
        validValues: @[default]
      ),
    )

proc date*(this: Schema, name:string, notNull=true): DbColumn =
  DbColumn(
    name: name,
    typ: DbType(kind: dbDate, notNull: notNull)
  )

proc datetime*(this: Schema, name: string, notNull=true): DbColumn =
  DbColumn(
    name: name,
    typ: DbType(kind: dbDatetime, notNull: notNull)
  )