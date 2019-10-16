import ../src/migration/model
import ../src/migration/SchemaBuilders
# from ../src/migration/SchemaBuilders import nullable, unsigned

Model().new(
  "test",
  [
    # Schema().bigIncrements("id"),
    # Schema().bigInteger("bigInteger"),
    # Schema().bigInteger("bigInteger_with_default", default=11),
    # Schema().bigInteger("bigInteger_null").nullable(),
    # Schema().binary("binary"),
    # Schema().binary("binary_null").nullable(),
    Schema().boolean("bool"),
    Schema().boolean("bool_true", default=true),
    Schema().boolean("bool_false").nullable(),
    # Schema().char("char", 4),
    # Schema().char("default_char1", 5, default=""),
    # Schema().char("default_char2", 6, default="default"),
    # Schema().date("date"),
    # Schema().date("date_null", nullable=true),
    # Schema().datetime("datetime")
  ]
).migrate()