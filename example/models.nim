import db_common
import ../src/migration/schemaBuilders


type Model* = ref object of RootObj
  name*: string
  columns*: seq[DbColumn]

proc migrate*(this:Model) =
  echo repr this


#=================================================================

Model(
  name:"users",
  columns: @[
    Schema().bigIncrements("id"),
    Schema().bigInteger("bigInteger"),
    Schema().binary("binary"),
    Schema().char("char", 4),
    Schema().char("default char", 4, default=""),
    Schema().date("date"),
  ]
).migrate()