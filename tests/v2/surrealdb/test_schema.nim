discard """
  cmd: "nim c -d:reset -r $file"
"""

# nim c -r -d:reset tests/v2/surrealdb/test_schema.nim

import std/unittest
import std/asyncdispatch
import std/json
import std/options
import ../../../src/allographer/schema_builder
import ../../../src/allographer/query_builder
import ../../connections
import ../../clear_tables


suite("SurrealDB create table"):
  test("create table"):
    surreal.create(
      table("relation", [
        Column.uuid("uuid").unique(),
      ]),
      table("TypeIndex", [
        Column.increments("index"),
        Column.integer("integer").unsigned().index().default(1),
        Column.smallInteger("smallInteger").unsigned().index().default(1),
        Column.mediumInteger("mediumInteger").unsigned().index().default(1),
        Column.bigInteger("bigInteger").unsigned().index().default(1),
        Column.decimal("decimal", 10, 3).unsigned().index().default(1.1),
        Column.double("double", 10, 3).unsigned().index().default(1.1),
        Column.float("float").unsigned().index().default(1.1),
        Column.uuid("uuid").index().default("A"),
        Column.char("char", 256).index().default("A"),
        Column.string("string").index().default("A"),
        Column.text("text").index().default("A"),
        Column.mediumText("mediumText").index().default("A"),
        Column.longText("longText").index().default("A"),
        Column.date("date").index().default(),
        Column.datetime("datetime1").index().default(Current),
        Column.datetime("datetime2").index().default(CurrentOnUpdate),
        Column.timestamp("timestamp").index().default(),
        Column.timestamps(),
        Column.softDelete(),
        Column.binary("binary").index().default("A"),
        Column.boolean("boolean").index().default(true),
        Column.enumField("enumField", ["A", "B", "C"]).index().default("A"),
        Column.json("json").index().default(%*{"key":"value"}),
        Column.foreign("relation").reference("id").onTable("relation").onDelete(SET_NULL).nullable(),
      ]),
      table("TypeUnique", [
        Column.increments("index"),
        Column.integer("integer").unsigned().index().unique().unique().default(1),
        Column.smallInteger("smallInteger").unsigned().index().unique().unique().default(1),
        Column.mediumInteger("mediumInteger").unsigned().index().unique().unique().default(1),
        Column.bigInteger("bigInteger").unsigned().index().unique().unique().default(1),
        Column.decimal("decimal", 10, 3).unsigned().index().unique().unique().default(1.1),
        Column.double("double", 10, 3).unsigned().index().unique().unique().default(1.1),
        Column.float("float").unsigned().index().unique().unique().default(1.1),
        Column.uuid("uuid").index().unique().unique().default("A"),
        Column.char("char", 256).index().unique().unique().default("A"),
        Column.string("string").index().unique().unique().default("A"),
        Column.text("text").index().unique().unique().default("A"),
        Column.mediumText("mediumText").index().unique().unique().default("A"),
        Column.longText("longText").index().unique().unique().default("A"),
        Column.date("date").index().unique().unique().default(),
        Column.datetime("datetime1").index().unique().unique().default(Current),
        Column.datetime("datetime2").index().unique().unique().default(CurrentOnUpdate),
        Column.timestamp("timestamp").index().unique().unique().default(),
        Column.timestamps(),
        Column.softDelete(),
        Column.binary("binary").index().unique().unique().default("A"),
        Column.boolean("boolean").index().unique().unique().default(true),
        Column.enumField("enumField", ["A", "B", "C"]).index().unique().default("A"),
        Column.json("json").index().unique().default(%*{"key":"value"}),
        Column.foreign("relation").reference("id").onTable("relation").onDelete(SET_NULL).nullable(),
      ]),
    )

    block:
      let info = surreal.raw(""" INFO FOR TABLE TypeIndex """).info().waitFor()
      let fields = info[0]["result"]["fd"]
      check fields["index"].getStr ==         "DEFINE FIELD index ON TypeIndex TYPE int"
      check fields["integer"].getStr ==       "DEFINE FIELD integer ON TypeIndex TYPE int VALUE $value OR 1 ASSERT $value != NONE AND $value >= 0"
      check fields["smallInteger"].getStr ==  "DEFINE FIELD smallInteger ON TypeIndex TYPE int VALUE $value OR 1 ASSERT $value != NONE AND $value >= 0"
      check fields["mediumInteger"].getStr == "DEFINE FIELD mediumInteger ON TypeIndex TYPE int VALUE $value OR 1 ASSERT $value != NONE AND $value >= 0"
      check fields["bigInteger"].getStr ==    "DEFINE FIELD bigInteger ON TypeIndex TYPE int VALUE $value OR 1 ASSERT $value != NONE AND $value >= 0"
      check fields["decimal"].getStr ==       "DEFINE FIELD decimal ON TypeIndex TYPE decimal VALUE $value OR 1.1 ASSERT $value != NONE AND $value >= 0"
      check fields["double"].getStr ==        "DEFINE FIELD double ON TypeIndex TYPE decimal VALUE $value OR 1.1 ASSERT $value != NONE AND $value >= 0"
      check fields["float"].getStr ==         "DEFINE FIELD float ON TypeIndex TYPE float VALUE $value OR 1.1 ASSERT $value != NONE AND $value >= 0"
      check fields["uuid"].getStr ==          "DEFINE FIELD uuid ON TypeIndex TYPE string VALUE $value OR rand::uuid() ASSERT $value != NONE"
      check fields["char"].getStr ==          "DEFINE FIELD char ON TypeIndex TYPE string VALUE $value OR 'A' ASSERT string::len($value) < 256 AND $value != NONE"
      check fields["string"].getStr ==        "DEFINE FIELD string ON TypeIndex TYPE string VALUE $value OR 'A' ASSERT string::len($value) < 256 AND $value != NONE"
      check fields["text"].getStr ==          "DEFINE FIELD text ON TypeIndex TYPE string VALUE $value OR 'A' ASSERT $value != NONE"
      check fields["mediumText"].getStr ==    "DEFINE FIELD mediumText ON TypeIndex TYPE string VALUE $value OR 'A' ASSERT $value != NONE"
      check fields["longText"].getStr ==      "DEFINE FIELD longText ON TypeIndex TYPE string VALUE $value OR 'A' ASSERT $value != NONE"
      check fields["date"].getStr ==          "DEFINE FIELD date ON TypeIndex TYPE datetime VALUE $value OR '1970-01-01T00:00:00Z' ASSERT $value != NONE"
      check fields["datetime1"].getStr ==     "DEFINE FIELD datetime1 ON TypeIndex TYPE datetime VALUE $value OR time::now() ASSERT $value != NONE"
      check fields["datetime2"].getStr ==     "DEFINE FIELD datetime2 ON TypeIndex TYPE datetime VALUE time::now() ASSERT $value != NONE"
      check fields["timestamp"].getStr ==     "DEFINE FIELD timestamp ON TypeIndex TYPE datetime VALUE $value OR '1970-01-01T00:00:00Z' ASSERT $value != NONE"
      check fields["created_at"].getStr ==    "DEFINE FIELD created_at ON TypeIndex TYPE datetime VALUE $value OR time::now()"
      check fields["updated_at"].getStr ==    "DEFINE FIELD updated_at ON TypeIndex TYPE datetime VALUE time::now()"
      check fields["deleted_at"].getStr ==    "DEFINE FIELD deleted_at ON TypeIndex TYPE datetime"
      check fields["binary"].getStr ==        "DEFINE FIELD binary ON TypeIndex TYPE string VALUE $value OR 'A' ASSERT $value != NONE"
      check fields["boolean"].getStr ==       "DEFINE FIELD boolean ON TypeIndex TYPE bool VALUE $value OR true ASSERT $value != NONE"
      check fields["enumField"].getStr ==     "DEFINE FIELD enumField ON TypeIndex TYPE string VALUE $value OR 'A' ASSERT $value INSIDE ['A', 'B', 'C'] AND $value != NONE"
      check fields["json"].getStr ==          "DEFINE FIELD json ON TypeIndex FLEXIBLE TYPE object VALUE $value OR { key: 'value' } ASSERT $value != NONE"
      check fields["relation"].getStr ==      "DEFINE FIELD relation ON TypeIndex TYPE record(relation) VALUE $value OR NULL"

      let indexs = info[0]["result"]["ix"]
      check indexs["TypeIndex_integer_index"].getStr ==       "DEFINE INDEX TypeIndex_integer_index ON TypeIndex FIELDS integer"
      check indexs["TypeIndex_smallInteger_index"].getStr ==  "DEFINE INDEX TypeIndex_smallInteger_index ON TypeIndex FIELDS smallInteger"
      check indexs["TypeIndex_mediumInteger_index"].getStr == "DEFINE INDEX TypeIndex_mediumInteger_index ON TypeIndex FIELDS mediumInteger"
      check indexs["TypeIndex_bigInteger_index"].getStr ==    "DEFINE INDEX TypeIndex_bigInteger_index ON TypeIndex FIELDS bigInteger"
      check indexs["TypeIndex_decimal_index"].getStr ==       "DEFINE INDEX TypeIndex_decimal_index ON TypeIndex FIELDS decimal"
      check indexs["TypeIndex_double_index"].getStr ==        "DEFINE INDEX TypeIndex_double_index ON TypeIndex FIELDS double"
      check indexs["TypeIndex_float_index"].getStr ==         "DEFINE INDEX TypeIndex_float_index ON TypeIndex FIELDS float"
      check indexs["TypeIndex_uuid_unique"].getStr ==         "DEFINE INDEX TypeIndex_uuid_unique ON TypeIndex FIELDS uuid UNIQUE"
      check indexs["TypeIndex_char_index"].getStr ==          "DEFINE INDEX TypeIndex_char_index ON TypeIndex FIELDS char"
      check indexs["TypeIndex_string_index"].getStr ==        "DEFINE INDEX TypeIndex_string_index ON TypeIndex FIELDS string"
      check indexs["TypeIndex_text_index"].getStr ==          "DEFINE INDEX TypeIndex_text_index ON TypeIndex FIELDS text"
      check indexs["TypeIndex_mediumText_index"].getStr ==    "DEFINE INDEX TypeIndex_mediumText_index ON TypeIndex FIELDS mediumText"
      check indexs["TypeIndex_longText_index"].getStr ==      "DEFINE INDEX TypeIndex_longText_index ON TypeIndex FIELDS longText"
      check indexs["TypeIndex_date_index"].getStr ==          "DEFINE INDEX TypeIndex_date_index ON TypeIndex FIELDS date"
      check indexs["TypeIndex_datetime1_index"].getStr ==     "DEFINE INDEX TypeIndex_datetime1_index ON TypeIndex FIELDS datetime1"
      check indexs["TypeIndex_datetime2_index"].getStr ==     "DEFINE INDEX TypeIndex_datetime2_index ON TypeIndex FIELDS datetime2"
      check indexs["TypeIndex_timestamp_index"].getStr ==     "DEFINE INDEX TypeIndex_timestamp_index ON TypeIndex FIELDS timestamp"
      check indexs["TypeIndex_created_at_index"].getStr ==    "DEFINE INDEX TypeIndex_created_at_index ON TypeIndex FIELDS created_at"
      check indexs["TypeIndex_updated_at_index"].getStr ==    "DEFINE INDEX TypeIndex_updated_at_index ON TypeIndex FIELDS updated_at"
      check indexs["TypeIndex_deleted_at_index"].getStr ==    "DEFINE INDEX TypeIndex_deleted_at_index ON TypeIndex FIELDS deleted_at"
      check indexs["TypeIndex_binary_index"].getStr ==        "DEFINE INDEX TypeIndex_binary_index ON TypeIndex FIELDS binary"
      check indexs["TypeIndex_boolean_index"].getStr ==       "DEFINE INDEX TypeIndex_boolean_index ON TypeIndex FIELDS boolean"
      check indexs["TypeIndex_enumField_index"].getStr ==     "DEFINE INDEX TypeIndex_enumField_index ON TypeIndex FIELDS enumField"
      check indexs["TypeIndex_json_index"].getStr ==          "DEFINE INDEX TypeIndex_json_index ON TypeIndex FIELDS json"

    block:
      let info = surreal.raw(""" INFO FOR TABLE TypeUnique """).info().waitFor()
      let fields = info[0]["result"]["fd"]
      check fields["index"].getStr ==         "DEFINE FIELD index ON TypeUnique TYPE int"
      check fields["integer"].getStr ==       "DEFINE FIELD integer ON TypeUnique TYPE int VALUE $value OR 1 ASSERT $value != NONE AND $value >= 0"
      check fields["smallInteger"].getStr ==  "DEFINE FIELD smallInteger ON TypeUnique TYPE int VALUE $value OR 1 ASSERT $value != NONE AND $value >= 0"
      check fields["mediumInteger"].getStr == "DEFINE FIELD mediumInteger ON TypeUnique TYPE int VALUE $value OR 1 ASSERT $value != NONE AND $value >= 0"
      check fields["bigInteger"].getStr ==    "DEFINE FIELD bigInteger ON TypeUnique TYPE int VALUE $value OR 1 ASSERT $value != NONE AND $value >= 0"
      check fields["decimal"].getStr ==       "DEFINE FIELD decimal ON TypeUnique TYPE decimal VALUE $value OR 1.1 ASSERT $value != NONE AND $value >= 0"
      check fields["double"].getStr ==        "DEFINE FIELD double ON TypeUnique TYPE decimal VALUE $value OR 1.1 ASSERT $value != NONE AND $value >= 0"
      check fields["float"].getStr ==         "DEFINE FIELD float ON TypeUnique TYPE float VALUE $value OR 1.1 ASSERT $value != NONE AND $value >= 0"
      check fields["uuid"].getStr ==          "DEFINE FIELD uuid ON TypeUnique TYPE string VALUE $value OR rand::uuid() ASSERT $value != NONE"
      check fields["char"].getStr ==          "DEFINE FIELD char ON TypeUnique TYPE string VALUE $value OR 'A' ASSERT string::len($value) < 256 AND $value != NONE"
      check fields["string"].getStr ==        "DEFINE FIELD string ON TypeUnique TYPE string VALUE $value OR 'A' ASSERT string::len($value) < 256 AND $value != NONE"
      check fields["text"].getStr ==          "DEFINE FIELD text ON TypeUnique TYPE string VALUE $value OR 'A' ASSERT $value != NONE"
      check fields["mediumText"].getStr ==    "DEFINE FIELD mediumText ON TypeUnique TYPE string VALUE $value OR 'A' ASSERT $value != NONE"
      check fields["longText"].getStr ==      "DEFINE FIELD longText ON TypeUnique TYPE string VALUE $value OR 'A' ASSERT $value != NONE"
      check fields["date"].getStr ==          "DEFINE FIELD date ON TypeUnique TYPE datetime VALUE $value OR '1970-01-01T00:00:00Z' ASSERT $value != NONE"
      check fields["datetime1"].getStr ==     "DEFINE FIELD datetime1 ON TypeUnique TYPE datetime VALUE $value OR time::now() ASSERT $value != NONE"
      check fields["datetime2"].getStr ==     "DEFINE FIELD datetime2 ON TypeUnique TYPE datetime VALUE time::now() ASSERT $value != NONE"
      check fields["timestamp"].getStr ==     "DEFINE FIELD timestamp ON TypeUnique TYPE datetime VALUE $value OR '1970-01-01T00:00:00Z' ASSERT $value != NONE"
      check fields["created_at"].getStr ==    "DEFINE FIELD created_at ON TypeUnique TYPE datetime VALUE $value OR time::now()"
      check fields["updated_at"].getStr ==    "DEFINE FIELD updated_at ON TypeUnique TYPE datetime VALUE time::now()"
      check fields["deleted_at"].getStr ==    "DEFINE FIELD deleted_at ON TypeUnique TYPE datetime"
      check fields["binary"].getStr ==        "DEFINE FIELD binary ON TypeUnique TYPE string VALUE $value OR 'A' ASSERT $value != NONE"
      check fields["boolean"].getStr ==       "DEFINE FIELD boolean ON TypeUnique TYPE bool VALUE $value OR true ASSERT $value != NONE"
      check fields["enumField"].getStr ==     "DEFINE FIELD enumField ON TypeUnique TYPE string VALUE $value OR 'A' ASSERT $value INSIDE ['A', 'B', 'C'] AND $value != NONE"
      check fields["json"].getStr ==          "DEFINE FIELD json ON TypeUnique FLEXIBLE TYPE object VALUE $value OR { key: 'value' } ASSERT $value != NONE"
      check fields["relation"].getStr ==      "DEFINE FIELD relation ON TypeUnique TYPE record(relation) VALUE $value OR NULL"

      let indexs = info[0]["result"]["ix"]
      check indexs["TypeUnique_integer_unique"].getStr ==       "DEFINE INDEX TypeUnique_integer_unique ON TypeUnique FIELDS integer UNIQUE"
      check indexs["TypeUnique_smallInteger_unique"].getStr ==  "DEFINE INDEX TypeUnique_smallInteger_unique ON TypeUnique FIELDS smallInteger UNIQUE"
      check indexs["TypeUnique_mediumInteger_unique"].getStr == "DEFINE INDEX TypeUnique_mediumInteger_unique ON TypeUnique FIELDS mediumInteger UNIQUE"
      check indexs["TypeUnique_bigInteger_unique"].getStr ==    "DEFINE INDEX TypeUnique_bigInteger_unique ON TypeUnique FIELDS bigInteger UNIQUE"
      check indexs["TypeUnique_decimal_unique"].getStr ==       "DEFINE INDEX TypeUnique_decimal_unique ON TypeUnique FIELDS decimal UNIQUE"
      check indexs["TypeUnique_double_unique"].getStr ==        "DEFINE INDEX TypeUnique_double_unique ON TypeUnique FIELDS double UNIQUE"
      check indexs["TypeUnique_float_unique"].getStr ==         "DEFINE INDEX TypeUnique_float_unique ON TypeUnique FIELDS float UNIQUE"
      check indexs["TypeUnique_uuid_unique"].getStr ==          "DEFINE INDEX TypeUnique_uuid_unique ON TypeUnique FIELDS uuid UNIQUE"
      check indexs["TypeUnique_char_unique"].getStr ==          "DEFINE INDEX TypeUnique_char_unique ON TypeUnique FIELDS char UNIQUE"
      check indexs["TypeUnique_string_unique"].getStr ==        "DEFINE INDEX TypeUnique_string_unique ON TypeUnique FIELDS string UNIQUE"
      check indexs["TypeUnique_text_unique"].getStr ==          "DEFINE INDEX TypeUnique_text_unique ON TypeUnique FIELDS text UNIQUE"
      check indexs["TypeUnique_mediumText_unique"].getStr ==    "DEFINE INDEX TypeUnique_mediumText_unique ON TypeUnique FIELDS mediumText UNIQUE"
      check indexs["TypeUnique_longText_unique"].getStr ==      "DEFINE INDEX TypeUnique_longText_unique ON TypeUnique FIELDS longText UNIQUE"
      check indexs["TypeUnique_date_unique"].getStr ==          "DEFINE INDEX TypeUnique_date_unique ON TypeUnique FIELDS date UNIQUE"
      check indexs["TypeUnique_datetime1_unique"].getStr ==     "DEFINE INDEX TypeUnique_datetime1_unique ON TypeUnique FIELDS datetime1 UNIQUE"
      check indexs["TypeUnique_datetime2_unique"].getStr ==     "DEFINE INDEX TypeUnique_datetime2_unique ON TypeUnique FIELDS datetime2 UNIQUE"
      check indexs["TypeUnique_timestamp_unique"].getStr ==     "DEFINE INDEX TypeUnique_timestamp_unique ON TypeUnique FIELDS timestamp UNIQUE"
      check indexs["TypeUnique_created_at_index"].getStr ==    "DEFINE INDEX TypeUnique_created_at_index ON TypeUnique FIELDS created_at"
      check indexs["TypeUnique_updated_at_index"].getStr ==    "DEFINE INDEX TypeUnique_updated_at_index ON TypeUnique FIELDS updated_at"
      check indexs["TypeUnique_deleted_at_index"].getStr ==    "DEFINE INDEX TypeUnique_deleted_at_index ON TypeUnique FIELDS deleted_at"
      check indexs["TypeUnique_binary_unique"].getStr ==        "DEFINE INDEX TypeUnique_binary_unique ON TypeUnique FIELDS binary UNIQUE"
      check indexs["TypeUnique_boolean_unique"].getStr ==       "DEFINE INDEX TypeUnique_boolean_unique ON TypeUnique FIELDS boolean UNIQUE"
      check indexs["TypeUnique_enumField_unique"].getStr ==     "DEFINE INDEX TypeUnique_enumField_unique ON TypeUnique FIELDS enumField UNIQUE"
      check indexs["TypeUnique_json_unique"].getStr ==          "DEFINE INDEX TypeUnique_json_unique ON TypeUnique FIELDS json UNIQUE"


  test("autoincrement"):
    surreal.create(
      table("test",[
        Column.increments("index"),
        Column.integer("index2").autoIncrement(),
        Column.string("string")
      ])
    )

    surreal.table("test").insert(%*{"string": "a"}).waitFor
    surreal.table("test").insert(%*{"string": "b"}).waitFor
    surreal.table("test").insert(%*{"string": "c"}).waitFor
    surreal.table("test").where("string", "=", "b").delete().waitFor
    surreal.table("test").insert(%*{"string": "d"}).waitFor

    let data = surreal.table("test").orderBy("index", Asc).get().waitFor
    for row in data:
      if row["string"].getStr == "a":
        check row["index"].getInt == 1
        check row["index2"].getInt == 1

      if row["string"].getStr == "c":
        check row["index"].getInt == 3
        check row["index2"].getInt == 3

      if row["string"].getStr == "d":
        check row["index2"].getInt == 4


  suite("Datetime"):
    test("datetime default"):
      surreal.create(
        table("test", [
          Column.string("name"),
          Column.datetime("created_at").default(Current),
          Column.datetime("updated_at").default(CurrentOnUpdate),
        ])
      )

      let aliceId = surreal.table("test").insertId(%*{"name": "alice"}).waitFor()
      
      var alice = surreal.table("test").find(aliceId).waitFor().get()
      echo alice
      let aliceCreatedAt1 = alice["created_at"].getStr()
      let aliceUpdatedAt1 = alice["updated_at"].getStr()

      surreal.table("test").where("id", "=", aliceId).update(%*{"name": "updated"}).waitFor()

      alice = surreal.table("test").find(aliceId).waitFor().get()
      echo alice
      let aliceCreatedAt2 = alice["created_at"].getStr()
      let aliceUpdatedAt2 = alice["updated_at"].getStr()

      check aliceCreatedAt1 == aliceCreatedAt2
      check aliceUpdatedAt1 != aliceUpdatedAt2


    test("timestamps"):
      surreal.create(
        table("test", [
          Column.string("name"),
          Column.timestamps()
        ])
      )

      let aliceId = surreal.table("test").insertId(%*{"name": "alice"}).waitFor()
      
      var alice = surreal.table("test").find(aliceId).waitFor().get()
      let aliceCreatedAt1 = alice["created_at"].getStr()
      let aliceUpdatedAt1 = alice["updated_at"].getStr()

      surreal.table("test").where("id", "=", aliceId).update(%*{"name": "updated"}).waitFor()

      alice = surreal.table("test").find(aliceId).waitFor().get()
      let aliceCreatedAt2 = alice["created_at"].getStr()
      let aliceUpdatedAt2 = alice["updated_at"].getStr()

      check aliceCreatedAt1 == aliceCreatedAt2
      check aliceUpdatedAt1 != aliceUpdatedAt2



suite("SurrealDB alter table"):
  setup:
    surreal.create(
      table("relation", [
        Column.uuid("uuid").unique(),
      ]),
      table("TypeUnique", [
        Column.integer("num"),
        Column.string("str"),
      ]),
      table("TypeIndex", [
        Column.integer("num"),
        Column.string("str"),
      ])
    )


  test("add column"):
    surreal.alter(
      table("TypeIndex", [
        Column.increments("index").add(),
        Column.integer("integer").unsigned().index().default(1).add(),
        Column.smallInteger("smallInteger").unsigned().index().default(1).add(),
        Column.mediumInteger("mediumInteger").unsigned().index().default(1).add(),
        Column.bigInteger("bigInteger").unsigned().index().default(1).add(),
        Column.decimal("decimal", 10, 3).unsigned().index().default(1.1).add(),
        Column.double("double", 10, 3).unsigned().index().default(1.1).add(),
        Column.float("float").unsigned().index().default(1.1).add(),
        Column.uuid("uuid").index().default("A").add(),
        Column.char("char", 256).index().default("A").add(),
        Column.string("string").index().default("A").add(),
        Column.text("text").index().default("A").add(),
        Column.mediumText("mediumText").index().default("A").add(),
        Column.longText("longText").index().default("A").add(),
        Column.date("date").index().default().add(),
        Column.datetime("datetime1").index().default(Current).add(),
        Column.datetime("datetime2").index().default(CurrentOnUpdate).add(),
        Column.timestamp("timestamp").index().default().add(),
        Column.timestamps().add(),
        Column.softDelete().add(),
        Column.binary("binary").index().default("A").add(),
        Column.boolean("boolean").index().default(true).add(),
        Column.enumField("enumField", ["A", "B", "C"]).index().default("A").add(),
        Column.json("json").index().default(%*{"key":"value"}).add(),
        Column.foreign("relation").reference("id").onTable("relation").onDelete(SET_NULL).nullable().add(),
      ]),
      table("TypeUnique", [
        Column.increments("index").add(),
        Column.integer("integer").unsigned().index().unique().unique().default(1).add(),
        Column.smallInteger("smallInteger").unsigned().index().unique().unique().default(1).add(),
        Column.mediumInteger("mediumInteger").unsigned().index().unique().unique().default(1).add(),
        Column.bigInteger("bigInteger").unsigned().index().unique().unique().default(1).add(),
        Column.decimal("decimal", 10, 3).unsigned().index().unique().unique().default(1.1).add(),
        Column.double("double", 10, 3).unsigned().index().unique().unique().default(1.1).add(),
        Column.float("float").unsigned().index().unique().unique().default(1.1).add(),
        Column.uuid("uuid").index().unique().unique().default("A").add(),
        Column.char("char", 256).index().unique().unique().default("A").add(),
        Column.string("string").index().unique().unique().default("A").add(),
        Column.text("text").index().unique().unique().default("A").add(),
        Column.mediumText("mediumText").index().unique().unique().default("A").add(),
        Column.longText("longText").index().unique().unique().default("A").add(),
        Column.date("date").index().unique().unique().default().add(),
        Column.datetime("datetime1").index().unique().unique().default(Current).add(),
        Column.datetime("datetime2").index().unique().unique().default(CurrentOnUpdate).add(),
        Column.timestamp("timestamp").index().unique().unique().default().add(),
        Column.timestamps().add(),
        Column.softDelete().add(),
        Column.binary("binary").index().unique().unique().default("A").add(),
        Column.boolean("boolean").index().unique().unique().default(true).add(),
        Column.enumField("enumField", ["A", "B", "C"]).index().unique().default("A").add(),
        Column.json("json").index().unique().default(%*{"key":"value"}).add(),
        Column.foreign("relation").reference("id").onTable("relation").onDelete(SET_NULL).nullable().add(),
      ]),
    )

    block:
      let info = surreal.raw(""" INFO FOR TABLE TypeIndex """).info().waitFor()
      let fields = info[0]["result"]["fd"]
      check fields["index"].getStr ==         "DEFINE FIELD index ON TypeIndex TYPE int"
      check fields["integer"].getStr ==       "DEFINE FIELD integer ON TypeIndex TYPE int VALUE $value OR 1 ASSERT $value != NONE AND $value >= 0"
      check fields["smallInteger"].getStr ==  "DEFINE FIELD smallInteger ON TypeIndex TYPE int VALUE $value OR 1 ASSERT $value != NONE AND $value >= 0"
      check fields["mediumInteger"].getStr == "DEFINE FIELD mediumInteger ON TypeIndex TYPE int VALUE $value OR 1 ASSERT $value != NONE AND $value >= 0"
      check fields["bigInteger"].getStr ==    "DEFINE FIELD bigInteger ON TypeIndex TYPE int VALUE $value OR 1 ASSERT $value != NONE AND $value >= 0"
      check fields["decimal"].getStr ==       "DEFINE FIELD decimal ON TypeIndex TYPE decimal VALUE $value OR 1.1 ASSERT $value != NONE AND $value >= 0"
      check fields["double"].getStr ==        "DEFINE FIELD double ON TypeIndex TYPE decimal VALUE $value OR 1.1 ASSERT $value != NONE AND $value >= 0"
      check fields["float"].getStr ==         "DEFINE FIELD float ON TypeIndex TYPE float VALUE $value OR 1.1 ASSERT $value != NONE AND $value >= 0"
      check fields["uuid"].getStr ==          "DEFINE FIELD uuid ON TypeIndex TYPE string VALUE $value OR rand::uuid() ASSERT $value != NONE"
      check fields["char"].getStr ==          "DEFINE FIELD char ON TypeIndex TYPE string VALUE $value OR 'A' ASSERT string::len($value) < 256 AND $value != NONE"
      check fields["string"].getStr ==        "DEFINE FIELD string ON TypeIndex TYPE string VALUE $value OR 'A' ASSERT string::len($value) < 256 AND $value != NONE"
      check fields["text"].getStr ==          "DEFINE FIELD text ON TypeIndex TYPE string VALUE $value OR 'A' ASSERT $value != NONE"
      check fields["mediumText"].getStr ==    "DEFINE FIELD mediumText ON TypeIndex TYPE string VALUE $value OR 'A' ASSERT $value != NONE"
      check fields["longText"].getStr ==      "DEFINE FIELD longText ON TypeIndex TYPE string VALUE $value OR 'A' ASSERT $value != NONE"
      check fields["date"].getStr ==          "DEFINE FIELD date ON TypeIndex TYPE datetime VALUE $value OR '1970-01-01T00:00:00Z' ASSERT $value != NONE"
      check fields["datetime1"].getStr ==     "DEFINE FIELD datetime1 ON TypeIndex TYPE datetime VALUE $value OR time::now() ASSERT $value != NONE"
      check fields["datetime2"].getStr ==     "DEFINE FIELD datetime2 ON TypeIndex TYPE datetime VALUE time::now() ASSERT $value != NONE"
      check fields["timestamp"].getStr ==     "DEFINE FIELD timestamp ON TypeIndex TYPE datetime VALUE $value OR '1970-01-01T00:00:00Z' ASSERT $value != NONE"
      check fields["created_at"].getStr ==    "DEFINE FIELD created_at ON TypeIndex TYPE datetime VALUE $value OR time::now()"
      check fields["updated_at"].getStr ==    "DEFINE FIELD updated_at ON TypeIndex TYPE datetime VALUE time::now()"
      check fields["deleted_at"].getStr ==    "DEFINE FIELD deleted_at ON TypeIndex TYPE datetime"
      check fields["binary"].getStr ==        "DEFINE FIELD binary ON TypeIndex TYPE string VALUE $value OR 'A' ASSERT $value != NONE"
      check fields["boolean"].getStr ==       "DEFINE FIELD boolean ON TypeIndex TYPE bool VALUE $value OR true ASSERT $value != NONE"
      check fields["enumField"].getStr ==     "DEFINE FIELD enumField ON TypeIndex TYPE string VALUE $value OR 'A' ASSERT $value INSIDE ['A', 'B', 'C'] AND $value != NONE"
      check fields["json"].getStr ==          "DEFINE FIELD json ON TypeIndex FLEXIBLE TYPE object VALUE $value OR { key: 'value' } ASSERT $value != NONE"
      check fields["relation"].getStr ==      "DEFINE FIELD relation ON TypeIndex TYPE record(relation) VALUE $value OR NULL"

      let indexs = info[0]["result"]["ix"]
      check indexs["TypeIndex_integer_index"].getStr ==       "DEFINE INDEX TypeIndex_integer_index ON TypeIndex FIELDS integer"
      check indexs["TypeIndex_smallInteger_index"].getStr ==  "DEFINE INDEX TypeIndex_smallInteger_index ON TypeIndex FIELDS smallInteger"
      check indexs["TypeIndex_mediumInteger_index"].getStr == "DEFINE INDEX TypeIndex_mediumInteger_index ON TypeIndex FIELDS mediumInteger"
      check indexs["TypeIndex_bigInteger_index"].getStr ==    "DEFINE INDEX TypeIndex_bigInteger_index ON TypeIndex FIELDS bigInteger"
      check indexs["TypeIndex_decimal_index"].getStr ==       "DEFINE INDEX TypeIndex_decimal_index ON TypeIndex FIELDS decimal"
      check indexs["TypeIndex_double_index"].getStr ==        "DEFINE INDEX TypeIndex_double_index ON TypeIndex FIELDS double"
      check indexs["TypeIndex_float_index"].getStr ==         "DEFINE INDEX TypeIndex_float_index ON TypeIndex FIELDS float"
      check indexs["TypeIndex_uuid_unique"].getStr ==         "DEFINE INDEX TypeIndex_uuid_unique ON TypeIndex FIELDS uuid UNIQUE"
      check indexs["TypeIndex_char_index"].getStr ==          "DEFINE INDEX TypeIndex_char_index ON TypeIndex FIELDS char"
      check indexs["TypeIndex_string_index"].getStr ==        "DEFINE INDEX TypeIndex_string_index ON TypeIndex FIELDS string"
      check indexs["TypeIndex_text_index"].getStr ==          "DEFINE INDEX TypeIndex_text_index ON TypeIndex FIELDS text"
      check indexs["TypeIndex_mediumText_index"].getStr ==    "DEFINE INDEX TypeIndex_mediumText_index ON TypeIndex FIELDS mediumText"
      check indexs["TypeIndex_longText_index"].getStr ==      "DEFINE INDEX TypeIndex_longText_index ON TypeIndex FIELDS longText"
      check indexs["TypeIndex_date_index"].getStr ==          "DEFINE INDEX TypeIndex_date_index ON TypeIndex FIELDS date"
      check indexs["TypeIndex_datetime1_index"].getStr ==     "DEFINE INDEX TypeIndex_datetime1_index ON TypeIndex FIELDS datetime1"
      check indexs["TypeIndex_datetime2_index"].getStr ==     "DEFINE INDEX TypeIndex_datetime2_index ON TypeIndex FIELDS datetime2"
      check indexs["TypeIndex_timestamp_index"].getStr ==     "DEFINE INDEX TypeIndex_timestamp_index ON TypeIndex FIELDS timestamp"
      check indexs["TypeIndex_created_at_index"].getStr ==    "DEFINE INDEX TypeIndex_created_at_index ON TypeIndex FIELDS created_at"
      check indexs["TypeIndex_updated_at_index"].getStr ==    "DEFINE INDEX TypeIndex_updated_at_index ON TypeIndex FIELDS updated_at"
      check indexs["TypeIndex_deleted_at_index"].getStr ==    "DEFINE INDEX TypeIndex_deleted_at_index ON TypeIndex FIELDS deleted_at"
      check indexs["TypeIndex_binary_index"].getStr ==        "DEFINE INDEX TypeIndex_binary_index ON TypeIndex FIELDS binary"
      check indexs["TypeIndex_boolean_index"].getStr ==       "DEFINE INDEX TypeIndex_boolean_index ON TypeIndex FIELDS boolean"
      check indexs["TypeIndex_enumField_index"].getStr ==     "DEFINE INDEX TypeIndex_enumField_index ON TypeIndex FIELDS enumField"
      check indexs["TypeIndex_json_index"].getStr ==          "DEFINE INDEX TypeIndex_json_index ON TypeIndex FIELDS json"

    block:
      let info = surreal.raw(""" INFO FOR TABLE TypeUnique """).info().waitFor()
      let fields = info[0]["result"]["fd"]
      check fields["index"].getStr ==         "DEFINE FIELD index ON TypeUnique TYPE int"
      check fields["integer"].getStr ==       "DEFINE FIELD integer ON TypeUnique TYPE int VALUE $value OR 1 ASSERT $value != NONE AND $value >= 0"
      check fields["smallInteger"].getStr ==  "DEFINE FIELD smallInteger ON TypeUnique TYPE int VALUE $value OR 1 ASSERT $value != NONE AND $value >= 0"
      check fields["mediumInteger"].getStr == "DEFINE FIELD mediumInteger ON TypeUnique TYPE int VALUE $value OR 1 ASSERT $value != NONE AND $value >= 0"
      check fields["bigInteger"].getStr ==    "DEFINE FIELD bigInteger ON TypeUnique TYPE int VALUE $value OR 1 ASSERT $value != NONE AND $value >= 0"
      check fields["decimal"].getStr ==       "DEFINE FIELD decimal ON TypeUnique TYPE decimal VALUE $value OR 1.1 ASSERT $value != NONE AND $value >= 0"
      check fields["double"].getStr ==        "DEFINE FIELD double ON TypeUnique TYPE decimal VALUE $value OR 1.1 ASSERT $value != NONE AND $value >= 0"
      check fields["float"].getStr ==         "DEFINE FIELD float ON TypeUnique TYPE float VALUE $value OR 1.1 ASSERT $value != NONE AND $value >= 0"
      check fields["uuid"].getStr ==          "DEFINE FIELD uuid ON TypeUnique TYPE string VALUE $value OR rand::uuid() ASSERT $value != NONE"
      check fields["char"].getStr ==          "DEFINE FIELD char ON TypeUnique TYPE string VALUE $value OR 'A' ASSERT string::len($value) < 256 AND $value != NONE"
      check fields["string"].getStr ==        "DEFINE FIELD string ON TypeUnique TYPE string VALUE $value OR 'A' ASSERT string::len($value) < 256 AND $value != NONE"
      check fields["text"].getStr ==          "DEFINE FIELD text ON TypeUnique TYPE string VALUE $value OR 'A' ASSERT $value != NONE"
      check fields["mediumText"].getStr ==    "DEFINE FIELD mediumText ON TypeUnique TYPE string VALUE $value OR 'A' ASSERT $value != NONE"
      check fields["longText"].getStr ==      "DEFINE FIELD longText ON TypeUnique TYPE string VALUE $value OR 'A' ASSERT $value != NONE"
      check fields["date"].getStr ==          "DEFINE FIELD date ON TypeUnique TYPE datetime VALUE $value OR '1970-01-01T00:00:00Z' ASSERT $value != NONE"
      check fields["datetime1"].getStr ==     "DEFINE FIELD datetime1 ON TypeUnique TYPE datetime VALUE $value OR time::now() ASSERT $value != NONE"
      check fields["datetime2"].getStr ==     "DEFINE FIELD datetime2 ON TypeUnique TYPE datetime VALUE time::now() ASSERT $value != NONE"
      check fields["timestamp"].getStr ==     "DEFINE FIELD timestamp ON TypeUnique TYPE datetime VALUE $value OR '1970-01-01T00:00:00Z' ASSERT $value != NONE"
      check fields["created_at"].getStr ==    "DEFINE FIELD created_at ON TypeUnique TYPE datetime VALUE $value OR time::now()"
      check fields["updated_at"].getStr ==    "DEFINE FIELD updated_at ON TypeUnique TYPE datetime VALUE time::now()"
      check fields["deleted_at"].getStr ==    "DEFINE FIELD deleted_at ON TypeUnique TYPE datetime"
      check fields["binary"].getStr ==        "DEFINE FIELD binary ON TypeUnique TYPE string VALUE $value OR 'A' ASSERT $value != NONE"
      check fields["boolean"].getStr ==       "DEFINE FIELD boolean ON TypeUnique TYPE bool VALUE $value OR true ASSERT $value != NONE"
      check fields["enumField"].getStr ==     "DEFINE FIELD enumField ON TypeUnique TYPE string VALUE $value OR 'A' ASSERT $value INSIDE ['A', 'B', 'C'] AND $value != NONE"
      check fields["json"].getStr ==          "DEFINE FIELD json ON TypeUnique FLEXIBLE TYPE object VALUE $value OR { key: 'value' } ASSERT $value != NONE"
      check fields["relation"].getStr ==      "DEFINE FIELD relation ON TypeUnique TYPE record(relation) VALUE $value OR NULL"

      let indexs = info[0]["result"]["ix"]
      check indexs["TypeUnique_integer_unique"].getStr ==       "DEFINE INDEX TypeUnique_integer_unique ON TypeUnique FIELDS integer UNIQUE"
      check indexs["TypeUnique_smallInteger_unique"].getStr ==  "DEFINE INDEX TypeUnique_smallInteger_unique ON TypeUnique FIELDS smallInteger UNIQUE"
      check indexs["TypeUnique_mediumInteger_unique"].getStr == "DEFINE INDEX TypeUnique_mediumInteger_unique ON TypeUnique FIELDS mediumInteger UNIQUE"
      check indexs["TypeUnique_bigInteger_unique"].getStr ==    "DEFINE INDEX TypeUnique_bigInteger_unique ON TypeUnique FIELDS bigInteger UNIQUE"
      check indexs["TypeUnique_decimal_unique"].getStr ==       "DEFINE INDEX TypeUnique_decimal_unique ON TypeUnique FIELDS decimal UNIQUE"
      check indexs["TypeUnique_double_unique"].getStr ==        "DEFINE INDEX TypeUnique_double_unique ON TypeUnique FIELDS double UNIQUE"
      check indexs["TypeUnique_float_unique"].getStr ==         "DEFINE INDEX TypeUnique_float_unique ON TypeUnique FIELDS float UNIQUE"
      check indexs["TypeUnique_uuid_unique"].getStr ==          "DEFINE INDEX TypeUnique_uuid_unique ON TypeUnique FIELDS uuid UNIQUE"
      check indexs["TypeUnique_char_unique"].getStr ==          "DEFINE INDEX TypeUnique_char_unique ON TypeUnique FIELDS char UNIQUE"
      check indexs["TypeUnique_string_unique"].getStr ==        "DEFINE INDEX TypeUnique_string_unique ON TypeUnique FIELDS string UNIQUE"
      check indexs["TypeUnique_text_unique"].getStr ==          "DEFINE INDEX TypeUnique_text_unique ON TypeUnique FIELDS text UNIQUE"
      check indexs["TypeUnique_mediumText_unique"].getStr ==    "DEFINE INDEX TypeUnique_mediumText_unique ON TypeUnique FIELDS mediumText UNIQUE"
      check indexs["TypeUnique_longText_unique"].getStr ==      "DEFINE INDEX TypeUnique_longText_unique ON TypeUnique FIELDS longText UNIQUE"
      check indexs["TypeUnique_date_unique"].getStr ==          "DEFINE INDEX TypeUnique_date_unique ON TypeUnique FIELDS date UNIQUE"
      check indexs["TypeUnique_datetime1_unique"].getStr ==     "DEFINE INDEX TypeUnique_datetime1_unique ON TypeUnique FIELDS datetime1 UNIQUE"
      check indexs["TypeUnique_datetime2_unique"].getStr ==     "DEFINE INDEX TypeUnique_datetime2_unique ON TypeUnique FIELDS datetime2 UNIQUE"
      check indexs["TypeUnique_timestamp_unique"].getStr ==     "DEFINE INDEX TypeUnique_timestamp_unique ON TypeUnique FIELDS timestamp UNIQUE"
      check indexs["TypeUnique_created_at_index"].getStr ==     "DEFINE INDEX TypeUnique_created_at_index ON TypeUnique FIELDS created_at"
      check indexs["TypeUnique_updated_at_index"].getStr ==     "DEFINE INDEX TypeUnique_updated_at_index ON TypeUnique FIELDS updated_at"
      check indexs["TypeUnique_deleted_at_index"].getStr ==     "DEFINE INDEX TypeUnique_deleted_at_index ON TypeUnique FIELDS deleted_at"
      check indexs["TypeUnique_binary_unique"].getStr ==        "DEFINE INDEX TypeUnique_binary_unique ON TypeUnique FIELDS binary UNIQUE"
      check indexs["TypeUnique_boolean_unique"].getStr ==       "DEFINE INDEX TypeUnique_boolean_unique ON TypeUnique FIELDS boolean UNIQUE"
      check indexs["TypeUnique_enumField_unique"].getStr ==     "DEFINE INDEX TypeUnique_enumField_unique ON TypeUnique FIELDS enumField UNIQUE"
      check indexs["TypeUnique_json_unique"].getStr ==          "DEFINE INDEX TypeUnique_json_unique ON TypeUnique FIELDS json UNIQUE"


  test("drop column"):
    surreal.alter(
      table("TypeIndex", [
        Column.dropColumn("str")
      ])
    )

    let columns = surreal.table("TypeIndex").columns().waitFor
    check not columns.contains("str")


  test("drop table"):
    surreal.create(
      table("TypeIndex", [
        Column.integer("num")
      ])
    )

    surreal.drop(
      table("TypeIndex")
    )

    let res = surreal.table("TypeIndex").first().waitFor()
    check not res.isSome


clearTables(surreal).waitFor()
