import unittest, json, times, os, strutils, asyncdispatch
import ../src/allographer/schema_builder
import ../src/allographer/query_builder

let dbTyp = getEnv("DB_DRIVER", "sqlite")
let host = getEnv("DB_CONNECTION").split(":")[0]
let port = try: getEnv("DB_CONNECTION").split(":")[1].parseInt.int32 except: 0
let maxConnections = getEnv("DB_MAX_CONNECTION").parseInt.int32
let driver = (proc():Driver=
  case dbTyp
  of "sqlite": return SQLite3
  of "mysql": return MySQL
  of "mariadb": return MariaDB
  of "postgres": return PostgreSQL
)()

let db = dbopen(driver, getEnv("DB_DATABASE"), getEnv("DB_USER"), getEnv("DB_PASSWORD"), host, port, maxConnections, 30)

suite "Schema builder":
  test "test":
    if dbTyp == "sqlite":
      db.schema(
        table("sqlite", [
          Column().increments("increments_column"),
          Column().integer("integer_column").unique().default(1).unsigned().index(),
          Column().smallInteger("smallInteger_column").unique().default(1).unsigned().index(),
          Column().mediumInteger("mediumInteger_column").unique().default(1).unsigned().index(),
          Column().bigInteger("bigInteger_column").unique().default(1).unsigned().index(),

          Column().decimal("decimal_column", 5, 2).unique().default(1).unsigned().index(),
          Column().double("double_column", 5, 2).unique().default(1).unsigned().index(),
          Column().float("float_column").unique().default(1).unsigned().index(),

          Column().char("char_column", 100).unique().default("").unsigned().index(),
          Column().string("string_column").unique().default("").unsigned().index(),
          Column().text("text_column").unique().default("").unsigned().index(),
          Column().mediumText("mediumText_column").unique().default("").unsigned().index(),
          Column().longText("longText_column").unique().default("").unsigned().index(),

          Column().date("date_column").unique().default().unsigned().index(),
          Column().datetime("datetime_column").unique().default().unsigned().index(),
          Column().time("time_column").unique().default().unsigned().index(),
          Column().timestamp("timestamp_column").unique().default().unsigned().index(),
          Column().timestamps(),
          Column().softDelete(),

          Column().binary("binary_column").unique().default().unsigned().index(),
          Column().boolean("boolean_column").unique().default().index(),
          Column().enumField("enumField_column", ["a", "b"]).unique().default().index(),
          Column().json("json_column").unique().default(%*{"key": "value"}).unsigned().index(),
        ], reset=true)
      )
    elif dbTyp == "mysql":
      db.schema(
        table("mysql", [
          Column().increments("increments_column"),
          Column().integer("integer_column").unique().default(1).unsigned(),
          Column().smallInteger("smallInteger_column").unique().default(1).unsigned(),
          Column().mediumInteger("mediumInteger_column").unique().default(1).unsigned(),
          Column().bigInteger("bigInteger_column").unique().default(1).unsigned(),

          Column().decimal("decimal_column", 5, 2).unique().default(1).unsigned(),
          Column().double("double_column", 5, 2).unique().default(1).unsigned(),
          Column().float("float_column").unique().default(1).unsigned(),

          Column().char("char_column", 100).unique().default(""),
          Column().string("string_column").unique().default(""),
          Column().text("text_column"),
          Column().mediumText("mediumText_column"),
          Column().longText("longText_column"),

          Column().date("date_column").unique().default(),
          Column().datetime("datetime_column").unique().default(),
          Column().time("time_column").unique().default(),
          Column().timestamp("timestamp_column").unique().default(),
          Column().timestamps(),
          Column().softDelete(),

          Column().binary("binary_column"),
          Column().boolean("boolean_column").unique().default(),
          Column().enumField("enumField_column", ["a", "b"]).unique().default("a"),
          Column().json("json_column"),
        ], reset=true)
      )
    elif dbTyp == "mariadb":
      discard
    elif dbTyp == "postgres":
      db.schema(
        table("postgres", [
          Column().increments("increments_column"),
          Column().integer("integer_column").unique().default(1).unsigned(),
          Column().smallInteger("smallInteger_column").unique().default(1).unsigned(),
          Column().mediumInteger("mediumInteger_column").unique().default(1).unsigned(),
          Column().bigInteger("bigInteger_column").unique().default(1).unsigned(),

          Column().decimal("decimal_column", 5, 2).unique().default(1).unsigned(),
          Column().double("double_column", 5, 2).unique().default(1).unsigned(),
          Column().float("float_column").unique().default(1).unsigned(),

          Column().char("char_column", 100).unique().default(""),
          Column().string("string_column").unique().default(""),
          Column().text("text_column").unique().default(""),
          Column().mediumText("mediumText_column").unique().default(""),
          Column().longText("longText_column").unique().default(""),

          Column().date("date_column").unique().default(),
          Column().datetime("datetime_column").unique().default(),
          Column().time("time_column").unique().default(),
          Column().timestamp("timestamp_column").unique().default(),
          Column().timestamps(),
          Column().softDelete(),

          Column().binary("binary_column").unique().default(),
          Column().boolean("boolean_column").unique().default(),
          Column().enumField("enumField_column", ["a", "b"]).unique().default(),
          Column().json("json_column").default(%*{"key": "value"}),
        ], reset=true)
      )

  test "insert":
    waitFor (proc(){.async.}=
      try:
        await db.table(dbTyp).insert(%*{
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
        db.alter(
          drop(dbTyp)
        )
      except:
        echo getCurrentExceptionMsg()
        assert false
    )()

