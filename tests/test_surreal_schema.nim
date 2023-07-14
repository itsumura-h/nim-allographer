discard """
  cmd: "nim c -d:reset -r $file"
"""

import std/unittest
import std/asyncdispatch
import std/json
import std/times
import std/strutils
import std/oids
import std/options
import ../src/allographer/connection
import ../src/allographer/schema_builder
import ../src/allographer/query_builder


let surreal = dbOpen(SurrealDb, "test", "test", "user", "pass", "http://surreal", 8000, 10, 30, true, false).waitFor()

suite("surreal schema"):
  setup:
    # discard
    surreal.raw("REMOVE TABLE `int_relation`").exec().waitFor()

  # test("raw define"):
  #   let define = """
  #     REMOVE TABLE types;
  #     DEFINE TABLE types SCHEMAFULL;
  #     DEFINE FIELD index ON TABLE types TYPE int;
  #     DEFINE INDEX types_index_unique ON TABLE types COLUMNS index UNIQUE;
  #     DEFINE FIELD bool ON TABLE types TYPE bool;
  #     DEFINE FIELD datetime ON TABLE types TYPE datetime;
  #     DEFINE FIELD decimal ON TABLE types TYPE decimal;
  #     DEFINE FIELD float ON TABLE types TYPE float;
  #     DEFINE FIELD int ON TABLE types TYPE int;
  #     DEFINE FIELD number ON TABLE types TYPE number;
  #     DEFINE FIELD object ON TABLE types TYPE object;
  #     DEFINE FIELD string ON TABLE types TYPE string;
  #   """
  #   surreal.raw(define).exec().waitFor()

  #   for i in 1..5:
  #     let id = surreal.table("types").insertId(%*{
  #       "index": i,
  #       "bool": true,
  #       "datetime": $(now()),
  #       "decimal": 1.11,
  #       "float": 1.11,
  #       "int": "rand()",
  #       "number": "rand()",
  #       "object": """ {"key": "value"} """,
  #       "string": "aaa"
  #     }).waitFor()
  #     echo surreal.table("types").find(id).waitFor().get().pretty()

  #   echo surreal.raw("INFO FOR TABLE types").info().waitFor().pretty()


  test("create table"):
    surreal.create(
      table("relation", [
        Column.uuid("id"),
      ]),
      table("TypeIndex", [
        Column.uuid("id").index().default("A"),
        Column.integer("integer").unsigned().index().default(1),
        Column.smallInteger("smallInteger").unsigned().index().default(1),
        Column.mediumInteger("mediumInteger").unsigned().index().default(1),
        Column.bigInteger("bigInteger").unsigned().index().default(1),
        Column.decimal("decimal", 10, 3).unsigned().index().default(1.1),
        Column.double("double", 10, 3).unsigned().index().default(1.1),
        Column.float("float").unsigned().index().default(1.1),
        Column.char("char", 255).index().default("A"),
        Column.string("string").index().default("A"),
        Column.text("text").index().default("A"),
        Column.mediumText("mediumText").index().default("A"),
        Column.longText("longText").index().default("A"),
        Column.date("date").index().default(),
        Column.datetime("datetime").index().default(),
        Column.timestamp("timestamp").index().default(),
        Column.timestamps(),
        Column.softDelete(),
        Column.binary("binary").index().default("A"),
        Column.boolean("boolean").index().default(true),
        Column.enumField("enumField", ["A", "B", "C"]).index().default("A"),
        Column.json("json").index().default(%*{"key":"value"}),
        Column.foreign("relation").reference("id").on("relation").onDelete(SET_NULL).nullable(),
      ]),
      table("TypeUnique", [
        Column.uuid("id").index().unique().unique().default("A"),
        Column.integer("integer").unsigned().index().unique().unique().default(1),
        Column.smallInteger("smallInteger").unsigned().index().unique().unique().default(1),
        Column.mediumInteger("mediumInteger").unsigned().index().unique().unique().default(1),
        Column.bigInteger("bigInteger").unsigned().index().unique().unique().default(1),
        Column.decimal("decimal", 10, 3).unsigned().index().unique().unique().default(1.1),
        Column.double("double", 10, 3).unsigned().index().unique().unique().default(1.1),
        Column.float("float").unsigned().index().unique().unique().default(1.1),
        Column.char("char", 255).index().unique().unique().default("A"),
        Column.string("string").index().unique().unique().default("A"),
        Column.text("text").index().unique().unique().default("A"),
        Column.mediumText("mediumText").index().unique().unique().default("A"),
        Column.longText("longText").index().unique().unique().default("A"),
        Column.date("date").index().unique().unique().default(),
        Column.datetime("datetime").index().unique().unique().default(),
        Column.timestamp("timestamp").index().unique().unique().default(),
        Column.timestamps(),
        Column.softDelete(),
        Column.binary("binary").index().unique().unique().default("A"),
        Column.boolean("boolean").index().unique().unique().default(true),
        Column.enumField("enumField", ["A", "B", "C"]).index().unique().default("A"),
        Column.json("json").index().unique().default(%*{"key":"value"}),
        Column.foreign("relation").reference("id").on("relation").onDelete(SET_NULL).nullable(),
      ]),
    )


    var info = surreal.raw(""" INFO FOR TABLE TypeIndex """).info().waitFor()
    var fields = info[0]["result"]["fd"]
    check fields["id"].getStr ==            "DEFINE FIELD id ON TypeIndex TYPE record(TypeIndex) VALUE $value OR 'TypeIndex:' + rand::guid() ASSERT $value != NONE"
    check fields["integer"].getStr ==       "DEFINE FIELD integer ON TypeIndex TYPE int VALUE $value OR 1 ASSERT $value != NONE AND $value >= 0"
    check fields["smallInteger"].getStr ==  "DEFINE FIELD smallInteger ON TypeIndex TYPE int VALUE $value OR 1 ASSERT $value != NONE AND $value >= 0"
    check fields["mediumInteger"].getStr == "DEFINE FIELD mediumInteger ON TypeIndex TYPE int VALUE $value OR 1 ASSERT $value != NONE AND $value >= 0"
    check fields["bigInteger"].getStr ==    "DEFINE FIELD bigInteger ON TypeIndex TYPE int VALUE $value OR 1 ASSERT $value != NONE AND $value >= 0"
    check fields["decimal"].getStr ==       "DEFINE FIELD decimal ON TypeIndex TYPE decimal VALUE $value OR 1.1 ASSERT $value != NONE AND $value >= 0"
    check fields["double"].getStr ==        "DEFINE FIELD double ON TypeIndex TYPE decimal VALUE $value OR 1.1 ASSERT $value != NONE AND $value >= 0"
    check fields["float"].getStr ==         "DEFINE FIELD float ON TypeIndex TYPE float VALUE $value OR 1.1 ASSERT $value != NONE AND $value >= 0"
    check fields["char"].getStr ==          "DEFINE FIELD char ON TypeIndex TYPE string VALUE $value OR 'A' ASSERT string::len($value) < 255 AND $value != NONE"
    check fields["string"].getStr ==        "DEFINE FIELD string ON TypeIndex TYPE string VALUE $value OR 'A' ASSERT string::len($value) < 255 AND $value != NONE"
    check fields["text"].getStr ==          "DEFINE FIELD text ON TypeIndex TYPE string VALUE $value OR 'A' ASSERT $value != NONE"
    check fields["mediumText"].getStr ==    "DEFINE FIELD mediumText ON TypeIndex TYPE string VALUE $value OR 'A' ASSERT $value != NONE"
    check fields["longText"].getStr ==      "DEFINE FIELD longText ON TypeIndex TYPE string VALUE $value OR 'A' ASSERT $value != NONE"
    check fields["date"].getStr ==          "DEFINE FIELD date ON TypeIndex TYPE datetime VALUE $value OR time::now() ASSERT $value != NONE"
    check fields["datetime"].getStr ==      "DEFINE FIELD datetime ON TypeIndex TYPE datetime VALUE $value OR time::now() ASSERT $value != NONE"
    check fields["timestamp"].getStr ==     "DEFINE FIELD timestamp ON TypeIndex TYPE datetime VALUE $value OR time::now() ASSERT $value != NONE"
    check fields["created_at"].getStr ==    "DEFINE FIELD created_at ON TypeIndex TYPE datetime VALUE time::now()"
    check fields["updated_at"].getStr ==    "DEFINE FIELD updated_at ON TypeIndex TYPE datetime VALUE time::now()"
    check fields["deleted_at"].getStr ==    "DEFINE FIELD deleted_at ON TypeIndex TYPE datetime"
    check fields["binary"].getStr ==        "DEFINE FIELD binary ON TypeIndex TYPE string VALUE $value OR 'A' ASSERT $value != NONE"
    check fields["boolean"].getStr ==       "DEFINE FIELD boolean ON TypeIndex TYPE bool VALUE $value OR true ASSERT $value != NONE"
    check fields["enumField"].getStr ==     "DEFINE FIELD enumField ON TypeIndex TYPE string VALUE $value OR 'A' ASSERT $value INSIDE ['A', 'B', 'C'] AND $value != NONE"
    check fields["json"].getStr ==          "DEFINE FIELD json ON TypeIndex FLEXIBLE TYPE object VALUE $value OR { key: 'value' } ASSERT $value != NONE"
    check fields["relation"].getStr ==      "DEFINE FIELD relation ON TypeIndex TYPE record(relation)"

    var indexs = info[0]["result"]["ix"]
    check indexs["TypeIndex_id_unique"].getStr ==           "DEFINE INDEX TypeIndex_id_unique ON TypeIndex FIELDS id UNIQUE"
    check indexs["TypeIndex_integer_index"].getStr ==       "DEFINE INDEX TypeIndex_integer_index ON TypeIndex FIELDS integer"
    check indexs["TypeIndex_smallInteger_index"].getStr ==  "DEFINE INDEX TypeIndex_smallInteger_index ON TypeIndex FIELDS smallInteger"
    check indexs["TypeIndex_mediumInteger_index"].getStr == "DEFINE INDEX TypeIndex_mediumInteger_index ON TypeIndex FIELDS mediumInteger"
    check indexs["TypeIndex_bigInteger_index"].getStr ==    "DEFINE INDEX TypeIndex_bigInteger_index ON TypeIndex FIELDS bigInteger"
    check indexs["TypeIndex_decimal_index"].getStr ==       "DEFINE INDEX TypeIndex_decimal_index ON TypeIndex FIELDS decimal"
    check indexs["TypeIndex_double_index"].getStr ==        "DEFINE INDEX TypeIndex_double_index ON TypeIndex FIELDS double"
    check indexs["TypeIndex_float_index"].getStr ==         "DEFINE INDEX TypeIndex_float_index ON TypeIndex FIELDS float"
    check indexs["TypeIndex_char_index"].getStr ==          "DEFINE INDEX TypeIndex_char_index ON TypeIndex FIELDS char"
    check indexs["TypeIndex_string_index"].getStr ==        "DEFINE INDEX TypeIndex_string_index ON TypeIndex FIELDS string"
    check indexs["TypeIndex_text_index"].getStr ==          "DEFINE INDEX TypeIndex_text_index ON TypeIndex FIELDS text"
    check indexs["TypeIndex_mediumText_index"].getStr ==    "DEFINE INDEX TypeIndex_mediumText_index ON TypeIndex FIELDS mediumText"
    check indexs["TypeIndex_longText_index"].getStr ==      "DEFINE INDEX TypeIndex_longText_index ON TypeIndex FIELDS longText"
    check indexs["TypeIndex_date_index"].getStr ==          "DEFINE INDEX TypeIndex_date_index ON TypeIndex FIELDS date"
    check indexs["TypeIndex_datetime_index"].getStr ==      "DEFINE INDEX TypeIndex_datetime_index ON TypeIndex FIELDS datetime"
    check indexs["TypeIndex_timestamp_index"].getStr ==     "DEFINE INDEX TypeIndex_timestamp_index ON TypeIndex FIELDS timestamp"
    check indexs["TypeIndex_created_at_index"].getStr ==    "DEFINE INDEX TypeIndex_created_at_index ON TypeIndex FIELDS created_at"
    check indexs["TypeIndex_updated_at_index"].getStr ==    "DEFINE INDEX TypeIndex_updated_at_index ON TypeIndex FIELDS updated_at"
    check indexs["TypeIndex_deleted_at_index"].getStr ==    "DEFINE INDEX TypeIndex_deleted_at_index ON TypeIndex FIELDS deleted_at"
    check indexs["TypeIndex_binary_index"].getStr ==        "DEFINE INDEX TypeIndex_binary_index ON TypeIndex FIELDS binary"
    check indexs["TypeIndex_boolean_index"].getStr ==       "DEFINE INDEX TypeIndex_boolean_index ON TypeIndex FIELDS boolean"
    check indexs["TypeIndex_enumField_index"].getStr ==     "DEFINE INDEX TypeIndex_enumField_index ON TypeIndex FIELDS enumField"
    check indexs["TypeIndex_json_index"].getStr ==          "DEFINE INDEX TypeIndex_json_index ON TypeIndex FIELDS json"


    info = surreal.raw(""" INFO FOR TABLE TypeUnique """).info().waitFor()
    fields = info[0]["result"]["fd"]
    check fields["id"].getStr ==            "DEFINE FIELD id ON TypeUnique TYPE record(TypeUnique) VALUE $value OR 'TypeUnique:' + rand::guid() ASSERT $value != NONE"
    check fields["integer"].getStr ==       "DEFINE FIELD integer ON TypeUnique TYPE int VALUE $value OR 1 ASSERT $value != NONE AND $value >= 0"
    check fields["smallInteger"].getStr ==  "DEFINE FIELD smallInteger ON TypeUnique TYPE int VALUE $value OR 1 ASSERT $value != NONE AND $value >= 0"
    check fields["mediumInteger"].getStr == "DEFINE FIELD mediumInteger ON TypeUnique TYPE int VALUE $value OR 1 ASSERT $value != NONE AND $value >= 0"
    check fields["bigInteger"].getStr ==    "DEFINE FIELD bigInteger ON TypeUnique TYPE int VALUE $value OR 1 ASSERT $value != NONE AND $value >= 0"
    check fields["decimal"].getStr ==       "DEFINE FIELD decimal ON TypeUnique TYPE decimal VALUE $value OR 1.1 ASSERT $value != NONE AND $value >= 0"
    check fields["double"].getStr ==        "DEFINE FIELD double ON TypeUnique TYPE decimal VALUE $value OR 1.1 ASSERT $value != NONE AND $value >= 0"
    check fields["float"].getStr ==         "DEFINE FIELD float ON TypeUnique TYPE float VALUE $value OR 1.1 ASSERT $value != NONE AND $value >= 0"
    check fields["char"].getStr ==          "DEFINE FIELD char ON TypeUnique TYPE string VALUE $value OR 'A' ASSERT string::len($value) < 255 AND $value != NONE"
    check fields["string"].getStr ==        "DEFINE FIELD string ON TypeUnique TYPE string VALUE $value OR 'A' ASSERT string::len($value) < 255 AND $value != NONE"
    check fields["text"].getStr ==          "DEFINE FIELD text ON TypeUnique TYPE string VALUE $value OR 'A' ASSERT $value != NONE"
    check fields["mediumText"].getStr ==    "DEFINE FIELD mediumText ON TypeUnique TYPE string VALUE $value OR 'A' ASSERT $value != NONE"
    check fields["longText"].getStr ==      "DEFINE FIELD longText ON TypeUnique TYPE string VALUE $value OR 'A' ASSERT $value != NONE"
    check fields["date"].getStr ==          "DEFINE FIELD date ON TypeUnique TYPE datetime VALUE $value OR time::now() ASSERT $value != NONE"
    check fields["datetime"].getStr ==      "DEFINE FIELD datetime ON TypeUnique TYPE datetime VALUE $value OR time::now() ASSERT $value != NONE"
    check fields["timestamp"].getStr ==     "DEFINE FIELD timestamp ON TypeUnique TYPE datetime VALUE $value OR time::now() ASSERT $value != NONE"
    check fields["created_at"].getStr ==    "DEFINE FIELD created_at ON TypeUnique TYPE datetime VALUE time::now()"
    check fields["updated_at"].getStr ==    "DEFINE FIELD updated_at ON TypeUnique TYPE datetime VALUE time::now()"
    check fields["deleted_at"].getStr ==    "DEFINE FIELD deleted_at ON TypeUnique TYPE datetime"
    check fields["binary"].getStr ==        "DEFINE FIELD binary ON TypeUnique TYPE string VALUE $value OR 'A' ASSERT $value != NONE"
    check fields["boolean"].getStr ==       "DEFINE FIELD boolean ON TypeUnique TYPE bool VALUE $value OR true ASSERT $value != NONE"
    check fields["enumField"].getStr ==     "DEFINE FIELD enumField ON TypeUnique TYPE string VALUE $value OR 'A' ASSERT $value INSIDE ['A', 'B', 'C'] AND $value != NONE"
    check fields["json"].getStr ==          "DEFINE FIELD json ON TypeUnique FLEXIBLE TYPE object VALUE $value OR { key: 'value' } ASSERT $value != NONE"
    check fields["relation"].getStr ==      "DEFINE FIELD relation ON TypeUnique TYPE record(relation)"

    indexs = info[0]["result"]["ix"]
    check indexs["TypeUnique_id_unique"].getStr ==           "DEFINE INDEX TypeUnique_id_unique ON TypeUnique FIELDS id UNIQUE"
    check indexs["TypeUnique_integer_unique"].getStr ==       "DEFINE INDEX TypeUnique_integer_unique ON TypeUnique FIELDS integer UNIQUE"
    check indexs["TypeUnique_smallInteger_unique"].getStr ==  "DEFINE INDEX TypeUnique_smallInteger_unique ON TypeUnique FIELDS smallInteger UNIQUE"
    check indexs["TypeUnique_mediumInteger_unique"].getStr == "DEFINE INDEX TypeUnique_mediumInteger_unique ON TypeUnique FIELDS mediumInteger UNIQUE"
    check indexs["TypeUnique_bigInteger_unique"].getStr ==    "DEFINE INDEX TypeUnique_bigInteger_unique ON TypeUnique FIELDS bigInteger UNIQUE"
    check indexs["TypeUnique_decimal_unique"].getStr ==       "DEFINE INDEX TypeUnique_decimal_unique ON TypeUnique FIELDS decimal UNIQUE"
    check indexs["TypeUnique_double_unique"].getStr ==        "DEFINE INDEX TypeUnique_double_unique ON TypeUnique FIELDS double UNIQUE"
    check indexs["TypeUnique_float_unique"].getStr ==         "DEFINE INDEX TypeUnique_float_unique ON TypeUnique FIELDS float UNIQUE"
    check indexs["TypeUnique_char_unique"].getStr ==          "DEFINE INDEX TypeUnique_char_unique ON TypeUnique FIELDS char UNIQUE"
    check indexs["TypeUnique_string_unique"].getStr ==        "DEFINE INDEX TypeUnique_string_unique ON TypeUnique FIELDS string UNIQUE"
    check indexs["TypeUnique_text_unique"].getStr ==          "DEFINE INDEX TypeUnique_text_unique ON TypeUnique FIELDS text UNIQUE"
    check indexs["TypeUnique_mediumText_unique"].getStr ==    "DEFINE INDEX TypeUnique_mediumText_unique ON TypeUnique FIELDS mediumText UNIQUE"
    check indexs["TypeUnique_longText_unique"].getStr ==      "DEFINE INDEX TypeUnique_longText_unique ON TypeUnique FIELDS longText UNIQUE"
    check indexs["TypeUnique_date_unique"].getStr ==          "DEFINE INDEX TypeUnique_date_unique ON TypeUnique FIELDS date UNIQUE"
    check indexs["TypeUnique_datetime_unique"].getStr ==      "DEFINE INDEX TypeUnique_datetime_unique ON TypeUnique FIELDS datetime UNIQUE"
    check indexs["TypeUnique_timestamp_unique"].getStr ==     "DEFINE INDEX TypeUnique_timestamp_unique ON TypeUnique FIELDS timestamp UNIQUE"
    check indexs["TypeUnique_created_at_index"].getStr ==    "DEFINE INDEX TypeUnique_created_at_index ON TypeUnique FIELDS created_at"
    check indexs["TypeUnique_updated_at_index"].getStr ==    "DEFINE INDEX TypeUnique_updated_at_index ON TypeUnique FIELDS updated_at"
    check indexs["TypeUnique_deleted_at_index"].getStr ==    "DEFINE INDEX TypeUnique_deleted_at_index ON TypeUnique FIELDS deleted_at"
    check indexs["TypeUnique_binary_unique"].getStr ==        "DEFINE INDEX TypeUnique_binary_unique ON TypeUnique FIELDS binary UNIQUE"
    check indexs["TypeUnique_boolean_unique"].getStr ==       "DEFINE INDEX TypeUnique_boolean_unique ON TypeUnique FIELDS boolean UNIQUE"
    check indexs["TypeUnique_enumField_unique"].getStr ==     "DEFINE INDEX TypeUnique_enumField_unique ON TypeUnique FIELDS enumField UNIQUE"
    check indexs["TypeUnique_json_unique"].getStr ==          "DEFINE INDEX TypeUnique_json_unique ON TypeUnique FIELDS json UNIQUE"
