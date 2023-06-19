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


# proc setUp(rdb:Rdb) =
#   rdb.create(
#     table("foreigh_table", [
#       Column.increments("id"),
#       Column.uuid("uuid"),
#       Column.string("name"),
#     ]),
#     table("DependSource", [
#       Column.string("string"),
#       Column.foreign("foreign_id").reference("id").on("foreigh_table").onDelete(SET_NULL),
#       Column.strForeign("foreign_uuid").reference("uuid").on("foreigh_table").onDelete(SET_NULL),
#     ]),
#     table("schema_builder", [
#       Column.increments("increments_column"),
#       Column.integer("integer_column").unique().default(1).unsigned().index(),
#       Column.smallInteger("smallInteger_column").unique().default(1).unsigned().index(),
#       Column.mediumInteger("mediumInteger_column").unique().default(1).unsigned().index(),
#       Column.bigInteger("bigInteger_column").unique().default(1).unsigned().index(),

#       Column.decimal("decimal_column", 5, 2).unique().default(1).unsigned().index(),
#       Column.double("double_column", 5, 2).unique().default(1).unsigned().index(),
#       Column.float("float_column").unique().default(1).unsigned().index(),

#       Column.uuid("uuid_column"),
#       Column.char("char_column", 100).unique().default("").index(),
#       Column.string("string_column").unique().default("").index(),
#       Column.text("text_column").index(),
#       Column.mediumText("mediumText_column").index(),
#       Column.longText("longText_column").index(),

#       Column.date("date_column").unique().default().index(),
#       Column.datetime("datetime_column").unique().default().index(),
#       Column.time("time_column").unique().default().index(),
#       Column.timestamp("timestamp_column").unique().default().index(),
#       Column.timestamps(),
#       Column.softDelete(),

#       Column.binary("binary_column").index(),
#       Column.boolean("boolean_column").unique().default().index(),
#       Column.enumField("enumField_column", ["a", "b"]).unique().default("a").index(),
#       Column.json("json_column").index(),

#       Column.foreign("foreign_id").reference("id").on("foreigh_table").onDelete(SET_NULL),
#       Column.strForeign("foreign_uuid").reference("uuid").on("foreigh_table").onDelete(SET_NULL),
#     ])
#   )
#   rdb.alter(
#     table("DependSource", [
#       # add column
#       Column.string("aaa").default("").add(),
#       Column.foreign("ccc").reference("id").on("foreigh_table").onDelete(SET_NULL).add(),
#       # change column definition
#       Column.string("aaa").nullable().change(),
#       # change column name
#       Column.renameColumn("aaa", "bbb"),
#       # delete column
#       Column.deleteColumn("bbb"),
#       Column.deleteColumn("ccc"),
#       Column.deleteColumn("foreign_id"),
#       Column.deleteColumn("foreign_uuid"),
#     ]),
#       # change table name
#     rename("DependSource", "DependSourceRenamed"),
#     # drop table
#     drop("DependSourceRenamed"),
#   )


# for rdb in dbConnections:
#   suite("schema builder"):
#     setup:
#       setUp(rdb)

#     test("schema builder " & rdb.driver.repr):
#       asyncBlock:
#         let uuid = $genOid()
#         rdb.table("foreigh_table").insert(%*{
#           "uuid": uuid,
#           "name": "a"
#         })
#         .await

#         rdb.table("schema_builder").insert(%*{
#           "increments_column": 1,
#           "integer_column": 0,
#           "smallInteger_column": 0,
#           "mediumInteger_column": 0,
#           "bigInteger_column": 1,
#           "decimal_column": 111.11,
#           "double_column": 111.11,
#           "float_column": 111.11,
#           "uuid_column": $genOid(),
#           "char_column": "a",
#           "string_column": "a",
#           "text_column": "a",
#           "mediumText_column": "a",
#           "longText_column": "a",
#           "date_column": now().format("yyyy-MM-dd"),
#           "datetime_column": now().format("yyyy-MM-dd HH:MM:ss"),
#           "time_column": now().format("HH:MM:ss"),
#           "timestamp_column": now().format("yyyy-MM-dd HH:MM:ss"),
#           "foreign_id": 1,
#           "foreign_uuid": uuid,
#           "binary_column": "a",
#           "boolean_column": true,
#           "enumField_column": "a",
#           "json_column": {"key": "value"}
#         })
#         .await
#         echo rdb.table("schema_builder")
#               .select("schema_builder.foreign_id", "schema_builder.foreign_uuid")
#               .join("foreigh_table", "foreigh_table.uuid", "=", "schema_builder.foreign_uuid")
#               .where("foreigh_table.id", "=", 1)
#               .get()
#               .await
#         rdb.alter(
#           drop("schema_builder"),
#           drop("foreigh_table")
#         )
#         check true

suite("schema builder"):
  for rdb in dbConnections:
    test($rdb.driver & " create table"):
      rdb.create(
        table("Relation", [
          Column.increments("id"),
        ]),
        table("Type", [
          Column.increments("id"),
          Column.integer("integer"),
          Column.smallInteger("smallInteger"),
          Column.mediumInteger("mediumInteger"),
          Column.bigInteger("bigInteger"),
          Column.decimal("decimal", 10, 3),
          Column.double("double", 10, 3),
          Column.float("float"),
          Column.char("char", 255),
          Column.string("string"),
          Column.text("text"),
          Column.mediumText("mediumText"),
          Column.longText("longText"),
          Column.date("date"),
          Column.datetime("datetime"),
          Column.time("time"),
          Column.timestamp("timestamp"),
          Column.timestamps(),
          Column.softDelete(),
          Column.binary("binary"),
          Column.boolean("boolean"),
          Column.enumField("enumField", ["A", "B", "C"]),
          Column.json("json"),
          Column.foreign("relation_id").reference("id").on("Relation").onDelete(SET_NULL)
        ])
      )

    suite($rdb.driver & " alter table"):
      test("add columns"):
        rdb.alter(
          table("Relation", [
            Column.string("name").add() 
          ]),
          table("Type", [
            Column.integer("add_integer").add(),
            Column.smallInteger("add_smallInteger").add(),
            Column.mediumInteger("add_mediumInteger").add(),
            Column.bigInteger("add_bigInteger").add(),
            Column.decimal("add_decimal", 10, 3).add(),
            Column.double("add_double", 10, 3).add(),
            Column.float("add_float").add(),
            Column.char("add_char", 255).add(),
            Column.string("add_string").add(),
            Column.uuid("add_uuid").add(),
            Column.text("add_text").add(),
            Column.mediumText("add_mediumText").add(),
            Column.longText("add_longText").add(),
            Column.date("add_date").add(),
            Column.datetime("add_datetime").add(),
            Column.time("add_time").add(),
            Column.timestamp("add_timestamp").add(),
            Column.binary("add_binary").add(),
            Column.boolean("add_boolean").add(),
            Column.enumField("add_enumField", ["A", "B", "C"]).add(),
            Column.json("add_json").add(),
          ])
        )

      test("change column"):
        rdb.alter(
          table("Type", [
            Column.integer("add_integer").unique().unsigned().index().default(1).change(),
            Column.smallInteger("add_smallInteger").unique().unsigned().index().default(1).change(),
            Column.mediumInteger("add_mediumInteger").unique().unsigned().index().default(1).change(),
            Column.bigInteger("add_bigInteger").unique().unsigned().index().default(1).change(),
            Column.decimal("add_decimal", 10, 3).unique().unsigned().index().default(1.1).change(),
            Column.double("add_double", 10, 3).unique().unsigned().index().default(1.1).change(),
            Column.float("add_float").unique().unsigned().index().default(1.1).change(),
            Column.char("add_char", 255).unique().index().default("A").change(),
            Column.string("add_string").unique().index().default("A").change(),
            Column.uuid("add_uuid").change(),
            Column.text("add_text").unique().index().default("A").change(),
            Column.mediumText("add_mediumText").unique().index().default("A").change(),
            Column.longText("add_longText").unique().index().default("A").change(),
            Column.date("add_date").unique().index().default().change(),
            Column.datetime("add_datetime").unique().index().default().change(),
            Column.time("add_time").unique().index().default().change(),
            Column.timestamp("add_timestamp").unique().index().default().change(),
            Column.binary("add_binary").unique().index().default("A").change(),
            Column.boolean("add_boolean").unique().index().default(true).change(),
            Column.enumField("add_enumField", ["A", "B", "C"]).unique().index().default("A").change(),
            Column.json("add_json").unique().index().default(%*{"key":"value"}).change(),
          ])
        )

      # test("rename column"):
      #   rdb.alter(
      #     table("User", [
      #       Column.renameColumn("email", "mailress")
      #     ])
      #   )

      # test("delete column"):
      #   rdb.alter(
      #     table("User", [
      #       Column.deleteColumn("mailress")
      #     ])
      #   )
