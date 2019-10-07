import db_common
import ../src/migration/model
import ../src/migration/schemaBuilders

#=================================================================

# Model(
#   name:"users",
#   columns: @[
#     Schema().bigIncrements("id"),
#     Schema().bigInteger("bigInteger"),
#     Schema().binary("binary"),
#     Schema().char("char", 4),
#     Schema().char("default char", 4, default=""),
#     Schema().date("date"),
#   ]
# ).migrate()

Model().new(
  "users",
  @[
    Schema().bigIncrements("id"),
    Schema().bigInteger("bigInteger"),
    Schema().binary("binary"),
    Schema().char("char", 4),
    Schema().char("default char", 4, default=""),
    Schema().date("date"),
  ]
).migrate()