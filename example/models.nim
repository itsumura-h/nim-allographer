import ../src/migration/model
import ../src/migration/SchemaBuilders
# from ../src/migration/SchemaBuilders import nullable, unsigned

Model().new(
  "table_name",
  [
    # int
    Schema().increments("id"),
    Schema().integer("integer"),
    Schema().integer("integer_default").default(2),
    Schema().integer("integer_null").nullable(),
    Schema().integer("integer_unsigned").unsigned(),
    Schema().integer("integer_null_unsigned").nullable().unsigned(),
    Schema().smallInteger("smallInteger"),
    Schema().smallInteger("smallInteger_default").default(3),
    Schema().smallInteger("smallInteger_null").nullable(),
    Schema().smallInteger("smallInteger_unsigned").unsigned(),
    Schema().smallInteger("smallInteger_null_unsigned").nullable().unsigned(),
    Schema().mediumInteger("mediumInteger"),
    Schema().mediumInteger("mediumInteger_default").default(4),
    Schema().mediumInteger("mediumInteger_null").nullable(),
    Schema().mediumInteger("mediumInteger_unsigned").unsigned(),
    Schema().mediumInteger("mediumInteger_null_unsigned").nullable().unsigned(),
    Schema().bigInteger("bigInteger"),
    Schema().bigInteger("bigInteger_default").default(5),
    Schema().bigInteger("bigInteger_null").nullable(),
    Schema().bigInteger("bigInteger_unsigned").unsigned(),
    Schema().bigInteger("bigInteger_null_unsigned").nullable().unsigned(),

    # float
    Schema().decimal("decimal", 5, 2),
    Schema().decimal("decimal_default", 6, 3).default(0.1),
    Schema().decimal("decimal_null", 7, 4).nullable(),
    Schema().decimal("decimal_unsigned", 7, 4).unsigned(),
    Schema().decimal("decimal_null_unsigned", 7, 4).nullable().unsigned(),
    Schema().double("double", 5, 1),
    Schema().double("double_default", 6, 3).default(0.2),
    Schema().double("double_null", 7, 4).nullable(),
    Schema().double("double_unsigned", 7, 4).unsigned(),
    Schema().double("double_null_unsigned", 7, 4).nullable().unsigned(),
    Schema().float("float"),
    Schema().float("float_default").default(0.3),
    Schema().float("float_null").nullable(),
    Schema().float("float_unsigned").unsigned(),
    Schema().float("float_null_unsigned").nullable().unsigned(),

    # char
    Schema().char("char", 4),
    Schema().char("char_default", 5).default("a"),
    Schema().char("char_null", 6).nullable(),
    Schema().string("string"),
    Schema().string("string_len", 4),
    Schema().string("string_default").default("b"),
    Schema().string("string_null").nullable(),
    Schema().text("text"),
    Schema().text("text_default").default("c"),
    Schema().text("text_nullable").nullable(),
    Schema().mediumText("mediumText"),
    Schema().mediumText("mediumText_default").default("d"),
    Schema().mediumText("mediumText_null").nullable(),
    Schema().longText("longText"),
    Schema().longText("longText_default").default("e"),
    Schema().longText("longText_null").nullable(),

    # date
    Schema().date("date"),
    Schema().date("date_null").nullable(),
    Schema().datetime("datetime"),
    Schema().datetime("datetime_null").nullable(),

    # other
    Schema().binary("binary"),
    Schema().binary("binary_null").nullable(),
    Schema().boolean("bool"),
    Schema().boolean("bool_default").default(true),
    Schema().boolean("bool_null").nullable(),
    Schema().enumField("enum", ["a", "b", "c"]),
    Schema().enumField("enum_default", ["d", "e"]).default("d"),
    Schema().enumField("enum_null", ["f", "g"]).nullable(),
  ]
).migrate()