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
    Schema().char("default_char", 5, default=""),
    Schema().char("default_char", 6, default="default"),
    Schema().date("date", nullable=true),
  ]
).migrate()