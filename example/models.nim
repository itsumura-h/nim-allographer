import ../src/allographer/schema_builder
# import allographer/schema_builder

Schema().create([
  Table().create("table_name", [
    # int
    Column().increments("id"),
    Column().integer("integer"),
    Column().integer("integer_default").default(2),
    Column().integer("integer_null").nullable(),
    Column().integer("integer_unsigned").unsigned(),
    Column().integer("integer_null_unsigned").nullable().unsigned(),
    Column().smallInteger("smallInteger"),
    Column().smallInteger("smallInteger_default").default(3),
    Column().smallInteger("smallInteger_null").nullable(),
    Column().smallInteger("smallInteger_unsigned").unsigned(),
    Column().smallInteger("smallInteger_null_unsigned").nullable().unsigned(),
    Column().mediumInteger("mediumInteger"),
    Column().mediumInteger("mediumInteger_default").default(4),
    Column().mediumInteger("mediumInteger_null").nullable(),
    Column().mediumInteger("mediumInteger_unsigned").unsigned(),
    Column().mediumInteger("mediumInteger_null_unsigned").nullable().unsigned(),
    Column().bigInteger("bigInteger"),
    Column().bigInteger("bigInteger_default").default(5),
    Column().bigInteger("bigInteger_null").nullable(),
    Column().bigInteger("bigInteger_unsigned").unsigned(),
    Column().bigInteger("bigInteger_null_unsigned").nullable().unsigned(),

    # float
    Column().decimal("decimal", 5, 2),
    Column().decimal("decimal_default", 6, 3).default(0.1),
    Column().decimal("decimal_null", 7, 4).nullable(),
    Column().decimal("decimal_unsigned", 7, 4).unsigned(),
    Column().decimal("decimal_null_unsigned", 7, 4).nullable().unsigned(),
    Column().double("double", 5, 1),
    Column().double("double_default", 6, 2).default(0.2),
    Column().double("double_null", 7, 3).nullable(),
    Column().double("double_unsigned", 8, 4).unsigned(),
    Column().double("double_null_unsigned", 9, 5).nullable().unsigned(),
    Column().float("float"),
    Column().float("float_default").default(0.3),
    Column().float("float_null").nullable(),
    Column().float("float_unsigned").unsigned(),
    Column().float("float_null_unsigned").nullable().unsigned(),

    # char
    Column().char("char", 4),
    Column().char("char_default", 5).default("a"),
    Column().char("char_null", 6).nullable(),
    Column().string("string"),
    Column().string("string_len", 4),
    Column().string("string_default").default("b"),
    Column().string("string_null").nullable(),
    Column().text("text"),
    Column().text("text_default").default("c"),
    Column().text("text_nullable").nullable(),
    Column().mediumText("mediumText"),
    Column().mediumText("mediumText_default").default("d"),
    Column().mediumText("mediumText_null").nullable(),
    Column().longText("longText"),
    Column().longText("longText_default").default("e"),
    Column().longText("longText_null").nullable(),

    # date
    Column().date("date"),
    Column().date("date_null").nullable(),
    Column().date("date_defualt").default(),
    Column().date("date_null_defualt").nullable().default(),
    Column().datetime("datetime"),
    Column().datetime("datetime_null").nullable(),
    Column().datetime("datetime_default").default(),
    Column().datetime("datetime_null_default").nullable().default(),
    Column().time("time"),
    Column().time("time_null").nullable(),
    Column().time("time_default").default(),
    Column().time("time_null_default").nullable().default(),
    Column().timestamp("timestamp"),
    Column().timestamp("timestamp_null").nullable(),
    Column().timestamp("timestamp_default").default(),
    Column().timestamp("timestamp_null_default").nullable().default(),
    Column().timestamps(),
    Column().softDelete(),

    # other
    Column().binary("_binary"),
    Column().binary("binary_null").nullable(),
    Column().boolean("bool"),
    Column().boolean("bool_null").nullable(),
    Column().boolean("bool_default").default(true),
    Column().boolean("bool_null_default").nullable().default(true),
    Column().enumField("enum", ["a", "b", "c"]),
    Column().enumField("enum_null", ["d", "e"]).nullable(),
    Column().enumField("enum_default", ["f", "g"]).default("f"),
    Column().enumField("enum_null_default", ["h", "i"]).nullable().default("h"),
    Column().json("json"),
    Column().json("json_null").nullable(),
  ], isRebuild=true),

  Table().create("auth", [
    Column().increments("id"),
    Column().string("name"),
    Column().timestamps()
  ]),

  Table().create("users", [
    Column().increments("id"),
    Column().string("name"),
    Column().foreign("auth_id").reference("id").on("auth").onDelete(SET_NULL)
  ])
])
