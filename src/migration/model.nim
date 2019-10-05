import db_common

type
  Column* = ref object of RootObj
    name*: string
    kind*: DbTypeKind
    primaryKey*: bool
    foreignKey*: bool
    foreignTable*: string

  Model* = ref object of RootObj
    name*: string
    columns*: seq[Column]

proc new*(this:Model, name:string, columns:varargs[Column]): Model =
  Model(
    name: name,
    columns: @columns
  )

proc new*(this:Column, name:string, kind:DbTypeKind, primaryKey=false,
          foreignKey=false, foreignTable=""): Column =
  Column(
    name:name,
    kind: kind,
    primaryKey: primaryKey,
    foreignKey: foreignKey,
    foreignTable: foreignTable
  )