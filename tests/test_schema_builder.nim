discard """
  cmd: "nim c -d:reset -r $file"
"""

import std/unittest
import std/json
import std/times
import std/os
import std/strutils
import std/asyncdispatch
import std/distros
import std/oids
import ../src/allographer/schema_builder
import ../src/allographer/query_builder
import ../src/allographer/connection
import ./connections


proc setUp(rdb:Rdb) =
  rdb.create(
    table("foreigh_table", [
      Column.increments("id"),
      Column.uuid("uuid"),
      Column.string("name"),
    ]),
    table("DependSource", [
      Column.string("string"),
      Column.foreign("foreign_id").reference("id").on("foreigh_table").onDelete(SET_NULL),
      Column.strForeign("foreign_uuid").reference("uuid").on("foreigh_table").onDelete(SET_NULL),
    ]),
    table("schema_builder", [
      Column.increments("increments_column"),
      Column.integer("integer_column").unique().default(1).unsigned().index(),
      Column.smallInteger("smallInteger_column").unique().default(1).unsigned().index(),
      Column.mediumInteger("mediumInteger_column").unique().default(1).unsigned().index(),
      Column.bigInteger("bigInteger_column").unique().default(1).unsigned().index(),

      Column.decimal("decimal_column", 5, 2).unique().default(1).unsigned().index(),
      Column.double("double_column", 5, 2).unique().default(1).unsigned().index(),
      Column.float("float_column").unique().default(1).unsigned().index(),

      Column.uuid("uuid_column"),
      Column.char("char_column", 100).unique().default("").index(),
      Column.string("string_column").unique().default("").index(),
      Column.text("text_column").index(),
      Column.mediumText("mediumText_column").index(),
      Column.longText("longText_column").index(),

      Column.date("date_column").unique().default().index(),
      Column.datetime("datetime_column").unique().default().index(),
      Column.time("time_column").unique().default().index(),
      Column.timestamp("timestamp_column").unique().default().index(),
      Column.timestamps(),
      Column.softDelete(),

      Column.binary("binary_column").index(),
      Column.boolean("boolean_column").unique().default().index(),
      Column.enumField("enumField_column", ["a", "b"]).unique().default("a").index(),
      Column.json("json_column").index(),

      Column.foreign("foreign_id").reference("id").on("foreigh_table").onDelete(SET_NULL),
      Column.strForeign("foreign_uuid").reference("uuid").on("foreigh_table").onDelete(SET_NULL),
    ])
  )
  rdb.alter(
    table("DependSource", [
      # add column
      Column.string("aaa").default("").add(),
      Column.foreign("ccc").reference("id").on("foreigh_table").onDelete(SET_NULL).add(),
      # change column definition
      Column.string("aaa").nullable().change(),
      # change column name
      Column.renameColumn("aaa", "bbb"),
      # delete column
      Column.deleteColumn("bbb"),
      Column.deleteColumn("ccc"),
      Column.deleteColumn("foreign_id"),
      Column.deleteColumn("foreign_uuid"),
    ]),
      # change table name
    rename("DependSource", "DependSourceRenamed"),
    # drop table
    drop("DependSourceRenamed"),
  )


for rdb in dbConnections:
  echo "==== " & rdb.driver.repr
  suite("schema builder"):
    setup:
      setUp(rdb)

    test("test1"):
      asyncBlock:
        let uuid = $genOid()
        rdb.table("foreigh_table").insert(%*{
          "uuid": uuid,
          "name": "a"
        })
        .await

        rdb.table("schema_builder").insert(%*{
          "increments_column": 1,
          "integer_column": 0,
          "smallInteger_column": 0,
          "mediumInteger_column": 0,
          "bigInteger_column": 1,
          "decimal_column": 111.11,
          "double_column": 111.11,
          "float_column": 111.11,
          "uuid_column": $genOid(),
          "char_column": "a",
          "string_column": "a",
          "text_column": "a",
          "mediumText_column": "a",
          "longText_column": "a",
          "date_column": now().format("yyyy-MM-dd"),
          "datetime_column": now().format("yyyy-MM-dd HH:MM:ss"),
          "time_column": now().format("HH:MM:ss"),
          "timestamp_column": now().format("yyyy-MM-dd HH:MM:ss"),
          "foreign_id": 1,
          "foreign_uuid": uuid,
          "binary_column": "a",
          "boolean_column": true,
          "enumField_column": "a",
          "json_column": {"key": "value"}
        })
        .await
        echo rdb.table("schema_builder")
              .select("schema_builder.foreign_id", "schema_builder.foreign_uuid")
              .join("foreigh_table", "foreigh_table.uuid", "=", "schema_builder.foreign_uuid")
              .where("foreigh_table.id", "=", 1)
              .get()
              .await
        rdb.alter(
          drop("schema_builder"),
          drop("foreigh_table")
        )
        check true
