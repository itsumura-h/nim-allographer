import ../src/migration/model
import ../src/migration/SchemaBuilders


Model().new(
  "test",
  @[
    Schema().bigIncrements("id"),
    Schema().bigInteger("bigInteger_with_default", default="1"),
    Schema().bigInteger("bigInteger", nullable=true),
    Schema().binary("binary"),
    Schema().boolean("bool"),
    Schema().boolean("bool_true", default="true"),
    Schema().boolean("bool_false", default="false"),
    Schema().char("char", 4),
    Schema().char("default_char1", 5, default=""),
    Schema().char("default_char2", 6, default="default"),
    Schema().date("date"),
    Schema().date("date_null", nullable=true),
    # Schema().datetime("datetime")
  ]
).migrate()