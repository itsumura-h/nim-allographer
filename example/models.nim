import ../src/migration/model
import ../src/migration/SchemaBuilders
# from ../src/migration/SchemaBuilders import nullable, unsigned

Model().new(
  "table_name",
  [
    Schema().increments("id"),
    Schema().bigInteger("bigInteger"),
    Schema().bigInteger("bigInteger_default", default=11),
    Schema().bigInteger("bigInteger_null").nullable(),
    Schema().binary("binary"),
    Schema().binary("binary_null").nullable(),
    Schema().boolean("bool"),
    Schema().boolean("bool_default", default=true),
    Schema().boolean("bool_null").nullable(),
    Schema().char("char", 4),
    Schema().char("char_default", 5, default=""),
    Schema().char("char_null", 6).nullable(),
    Schema().date("date"),
    Schema().date("date_null").nullable(),
    Schema().datetime("datetime"),
    Schema().datetime("datetime_null").nullable(),
    Schema().decimal("decimal", 5, 2),
    Schema().decimal("decimal_default", 6, 3, default=0.1),
    Schema().decimal("decimal_null", 7, 4).nullable(),
    Schema().double("double", 5, 1),
    Schema().double("double_default", 6, 3, default=0.1),
    Schema().double("double_null", 7, 4).nullable(),
    Schema().enumField("enum", ["a", "b", "c"]),
    Schema().enumField("enum_default", ["d", "e"], default="a"),
    Schema().enumField("enum_null", ["f", "g"]).nullable(),
  ]
).migrate()