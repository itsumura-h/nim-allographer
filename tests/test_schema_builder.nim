import unittest, json, times, os
import ../src/allographer/schema_builder
import ../src/allographer/query_builder

let dbTyp = getEnv("DB_DRIVER", "sqlite")

suite "Schema builder":
  test "test":
    schema([
      table("sqlite", [
        Column().increments("increments"),
        Column().integer("integer").unique().default(1).unsigned().index(),
        Column().smallInteger("smallInteger").unique().default(1).unsigned().index(),
        Column().mediumInteger("mediumInteger").unique().default(1).unsigned().index(),
        Column().bigInteger("bigInteger").unique().default(1).unsigned().index(),

        Column().decimal("decimal", 5, 2).unique().default(1).unsigned().index(),
        Column().double("double", 5, 2).unique().default(1).unsigned().index(),
        Column().float("float").unique().default(1).unsigned().index(),

        Column().char("char", 100).unique().default("").unsigned().index(),
        Column().string("string").unique().default("").unsigned().index(),
        Column().text("text").unique().default("").unsigned().index(),
        Column().mediumText("mediumText").unique().default("").unsigned().index(),
        Column().longText("longText").unique().default("").unsigned().index(),

        Column().date("date").unique().default().unsigned().index(),
        Column().datetime("datetime").unique().default().unsigned().index(),
        Column().time("time").unique().default().unsigned().index(),
        Column().timestamp("timestamp").unique().default().unsigned().index(),
        Column().timestamps(),
        Column().softDelete(),

        Column().binary("binary").unique().default().unsigned().index(),
        Column().boolean("boolean").unique().default().index(),
        Column().enumField("enumField", ["a", "b"]).unique().default().index(),
        Column().json("json").unique().default(%*{"key": "value"}).unsigned().index(),
      ], reset=true),

      # table("mysql", [
      #   Column().increments("increments_column"),
      #   Column().integer("integer_column").unique().default(1).unsigned(),
      #   Column().smallInteger("smallInteger_column").unique().default(1).unsigned(),
      #   Column().mediumInteger("mediumInteger_column").unique().default(1).unsigned(),
      #   Column().bigInteger("bigInteger_column").unique().default(1).unsigned(),

      #   Column().decimal("decimal_column", 5, 2).unique().default(1).unsigned(),
      #   Column().double("double_column", 5, 2).unique().default(1).unsigned(),
      #   Column().float("float_column").unique().default(1).unsigned(),

      #   Column().char("char_column", 100).unique().default(""),
      #   Column().string("string_column").unique().default(""),
      #   Column().text("text_column"),
      #   Column().mediumText("mediumText_column"),
      #   Column().longText("longText_column"),

      #   Column().date("date_column").unique().default(),
      #   Column().datetime("datetime_column").unique().default(),
      #   Column().time("time_column").unique().default(),
      #   Column().timestamp("timestamp_column").unique().default(),
      #   Column().timestamps(),
      #   Column().softDelete(),

      #   Column().binary("binary_column"),
      #   Column().boolean("boolean_column").unique().default(),
      #   Column().enumField("enumField_column", ["a", "b"]).unique().default("a"),
      #   Column().json("json_column"),
      # ], reset=true),

      # table("postgres", [
      #   Column().increments("increments_column"),
      #   Column().integer("integer_column").unique().default(1).unsigned(),
      #   Column().smallInteger("smallInteger_column").unique().default(1).unsigned(),
      #   Column().mediumInteger("mediumInteger_column").unique().default(1).unsigned(),
      #   Column().bigInteger("bigInteger_column").unique().default(1).unsigned(),

      #   Column().decimal("decimal_column", 5, 2).unique().default(1).unsigned(),
      #   Column().double("double_column", 5, 2).unique().default(1).unsigned(),
      #   Column().float("float_column").unique().default(1).unsigned(),

      #   Column().char("char_column", 100).unique().default(""),
      #   Column().string("string_column").unique().default(""),
      #   Column().text("text_column").unique().default(""),
      #   Column().mediumText("mediumText_column").unique().default(""),
      #   Column().longText("longText_column").unique().default(""),

      #   Column().date("date_column").unique().default(),
      #   Column().datetime("datetime_column").unique().default(),
      #   Column().time("time_column").unique().default(),
      #   Column().timestamp("timestamp_column").unique().default(),
      #   Column().timestamps(),
      #   Column().softDelete(),

      #   Column().binary("binary_column").unique().default(),
      #   Column().boolean("boolean_column").unique().default(),
      #   Column().enumField("enumField_column", ["a", "b"]).unique().default(),
      #   Column().json("json_column").default(%*{"key": "value"}),
      # ], reset=true)
    ])

  test "insert":
    try:
      rdb().table(dbTyp).insert(%*{
        "increments_column": 1,
        "integer_column": 1,
        "smallInteger_column": 1,
        "mediumInteger_column": 1,
        "bigInteger_column": 1,
        "decimal_column": 111.11,
        "double_column": 111.11,
        "float_column": 111.11,
        "char_column": "a",
        "string_column": "a",
        "text_column": "a",
        "mediumText_column": "a",
        "longText_column": "a",
        "date_column": "2020-01-01".parse("yyyy-MM-dd").format("yyyy-MM-dd"),
        "datetime_column": "2020-01-01".parse("yyyy-MM-dd").format("yyyy-MM-dd HH:MM:ss"),
        "time_column": "2020-01-01".parse("yyyy-MM-dd").format("HH:MM:ss"),
        "timestamp_column": "2020-01-01".parse("yyyy-MM-dd").format("yyyy-MM-dd HH:MM:ss"),
        "binary_column": "a",
        "boolean_column": true,
        "enumField_column": "a",
        "json_column": {"key": "value"}
      })
      assert true
      alter(
        drop(dbTyp)
      )
    except:
      echo getCurrentExceptionMsg()
      assert false
