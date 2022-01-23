discard """
  cmd: "nim c -d:reset -r $file"
"""

import unittest, json, times, os, strutils, asyncdispatch, distros, oids
import ../src/allographer/schema_builder
import ../src/allographer/query_builder
import ../src/allographer/connection

let maxConnections = getEnv("DB_MAX_CONNECTION").parseInt

let sqliteDb = dbopen(SQLite3, ":memory:", maxConnections=95, timeout=30, shouldDisplayLog=true)
let postgresDb = dbopen(PostgreSQL, getEnv("DB_DATABASE"), getEnv("DB_USER"), getEnv("DB_PASSWORD"), getEnv("PG_HOST"), getEnv("PG_PORT").parseInt, maxConnections, 30, shouldDisplayLog=true)
let mysqlDb = dbopen(MySQL, getEnv("DB_DATABASE"), getEnv("DB_USER"), getEnv("DB_PASSWORD"), getEnv("MY_HOST"), getEnv("MY_PORT").parseInt, maxConnections, 30, shouldDisplayLog=true)
let mariaDb = dbopen(MariaDB, getEnv("DB_DATABASE"), getEnv("DB_USER"), getEnv("DB_PASSWORD"), getEnv("MARIA_HOST"), getEnv("MY_PORT").parseInt, maxConnections, 30, shouldDisplayLog=true)


block:
  echo "=== sqlite"
  sqliteDb.schema(
    table("foreigh_table", [
      Column().increments("id"),
      Column().uuid("uuid"),
      Column().string("name"),
    ]),
    table("schema_builder", [
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

      Column().foreign("foreign_id").reference("id").on("foreigh_table").onDelete(SET_NULL),
      Column().strForeign("uuid").reference("uuid").on("foreigh_table").onDelete(SET_NULL),

      Column().binary("binary_column").unique().default().unsigned().index(),
      Column().boolean("boolean_column").unique().default().index(),
      Column().enumField("enumField_column", ["a", "b"]).unique().default().index(),
      Column().json("json_column").unique().default(%*{"key": "value"}).unsigned().index(),
    ])
  )
  if detectOs(Ubuntu):
    echo "=== mysql"
    mysqlDb.schema(
      table("foreigh_table", [
        Column().increments("id"),
        Column().uuid("uuid"),
        Column().string("name"),
      ]),
      table("schema_builder", [
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

        Column().foreign("foreign_id").reference("id").on("foreigh_table").onDelete(SET_NULL),
        Column().strForeign("uuid").reference("uuid").on("foreigh_table").onDelete(SET_NULL),

        Column().binary("binary_column"),
        Column().boolean("boolean_column").unique().default(),
        Column().enumField("enumField_column", ["a", "b"]).unique().default("a"),
        Column().json("json_column"),
      ])
    )
  echo "=== mariadb"
  mariaDb.schema(
    table("foreigh_table", [
      Column().increments("id"),
      Column().uuid("uuid"),
      Column().string("name"),
    ]),
    table("schema_builder", [
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

      Column().foreign("foreign_id").reference("id").on("foreigh_table").onDelete(SET_NULL),
      Column().strForeign("uuid").reference("uuid").on("foreigh_table").onDelete(SET_NULL),

      Column().binary("binary_column"),
      Column().boolean("boolean_column").unique().default(),
      Column().enumField("enumField_column", ["a", "b"]).unique().default("a"),
      Column().json("json_column"),
    ])
  )
  echo "=== postgres"
  postgresDb.schema(
    table("foreigh_table", [
      Column().increments("id"),
      Column().uuid("uuid"),
      Column().string("name"),
    ]),
    table("schema_builder", [
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

      Column().foreign("foreign_id").reference("id").on("foreigh_table").onDelete(SET_NULL),
      Column().strForeign("uuid").reference("uuid").on("foreigh_table").onDelete(SET_NULL),

      Column().binary("binary_column").unique().default(),
      Column().boolean("boolean_column").unique().default(),
      Column().enumField("enumField_column", ["a", "b"]).unique().default(),
      Column().json("json_column").default(%*{"key": "value"}),
    ])
  )

block:
  waitFor (proc(){.async.}=
    try:
      let list =
        if detectOs(Ubuntu):
          @[sqliteDb, mysqlDb, mariaDb, postgresDb]
        else:
          @[sqliteDb, mariaDb, postgresDb]
      for rdb in list:
        let uuid = $genOid()
        await rdb.table("foreigh_table").insert(%*{
          "uuid": uuid,
          "name": "a"
        })
        await rdb.table("schema_builder").insert(%*{
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
          "foreign_id": 1,
          "uuid": uuid,
          "binary_column": "a",
          "boolean_column": true,
          "enumField_column": "a",
          "json_column": {"key": "value"}
        })
        # echo await rdb.table("schema_builder").get()
        echo await rdb.table("schema_builder")
                    .select("schema_builder.foreign_id", "schema_builder.uuid")
                    .join("foreigh_table", "foreigh_table.uuid", "=", "schema_builder.uuid")
                    .where("foreigh_table.id", "=", 1)
                    .get()
        assert true
        rdb.alter(
          drop("schema_builder")
        )
    except:
      echo getCurrentExceptionMsg()
      assert false
  )()
