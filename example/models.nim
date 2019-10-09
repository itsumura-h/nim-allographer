import db_common, strformat
import ../src/migration/schemaBuilders


type Model* = ref object of RootObj
  name*: string
  columns*: seq[DbColumn]

proc migrate*(this:Model) =
  # echo repr this
  var query = ""

  # create table
  query.add(
    &"CREATE TABLE {this.name};"
  )
  for column in this.columns:
    echo repr column

  echo query


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