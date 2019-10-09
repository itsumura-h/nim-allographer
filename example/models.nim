import ../src/migration/model
import ../src/migration/schemaBuilders


Model().new(
  "users",
  @[
    Schema().bigIncrements("id"),
    Schema().bigInteger("bigInteger"),
    Schema().boolean("bool"),
    Schema().binary("binary"),
    Schema().char("char", 4),
    Schema().char("default char", 4, default=""),
    Schema().date("date"),
  ]
).migrate()