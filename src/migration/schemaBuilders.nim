import db_common

type Schema* = ref object of RootObj


proc bigIncrements*(this: Schema, name:string): DbColumn =
  DbColumn(
    name: name,
    typ: DbType(kind: dbSerial, notNull: true)
  )

proc bigInteger*(this: Schema, name:string, nullable=false): DbColumn =
  DbColumn(
    name: name,
    typ: DbType(kind: dbInt, notNull: not nullable)
  )

proc binary*(this: Schema, name:string, nullable=false): DbColumn =
  DbColumn(
    name: name,
    typ: DbType(kind: dbBlob, notNull: not nullable)
  )

proc boolean*(this: Schema, name:string, nullable=false): DbColumn =
  DbColumn(
    name: name,
    typ: DbType(kind: dbBool, notNull: not nullable)
  )

proc char*(this: Schema, name:string, maxReprLen:int, nullable=false,
            default="default null"): DbColumn =
  if default == "default null":
    DbColumn(
      name: name,
      typ: DbType(
        kind: dbFixedChar,
        maxReprLen: maxReprLen,
        notNull: not nullable
      ),
    )
  else:
    DbColumn(
      name: name,
      typ: DbType(
        kind: dbFixedChar,
        maxReprLen: maxReprLen,
        notNull: not nullable,
        validValues: @[default]
      ),
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