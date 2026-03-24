discard """
  cmd: "nim c -d:reset $file"
"""

# nim c -r -d:reset -d:ssl tests/surrealdb/test_schema.nim

import std/unittest
import std/asyncdispatch
import std/json
import std/options
import std/strutils
import ../../src/allographer/schema_builder
import ../../src/allographer/query_builder
import ./connections
import ../clear_tables


proc normalizeInfoDef(s: string): string =
  result = s
  result = result.replace("`rand`::uuid()", "rand::uuid()")
  result = result.replace("1.1f", "1.1")
  result = result.replace("| none", "| NONE")
  result = result.replace("| None", "| NONE")
  result = result.replace(" PERMISSIONS FULL", "")
  result = result.replace("{ key: 'value' }", "{\"key\":\"value\"}")
  result = result.replace("{ key: \"value\" }", "{\"key\":\"value\"}")
  result = result.replace("{key:'value'}", "{\"key\":\"value\"}")


proc `==`(a, b: string): bool =
  cmp(normalizeInfoDef(a), normalizeInfoDef(b)) == 0


proc expectInfoEntries(node: JsonNode, entries: seq[tuple[key: string, expected: string]]) =
  for entry in entries:
    check normalizeInfoDef(node[entry.key].getStr()) == normalizeInfoDef(entry.expected)


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
      let resultNode = info[0]["result"]
      let fields = resultNode["fields"]
      expectInfoEntries(fields, @[
        ("index",         "DEFINE FIELD index ON TypeIndex TYPE int VALUE $value OR (SELECT max_index FROM _autoincrement_sequences WHERE `table` = 'TypeIndex' AND column = 'index' LIMIT 1)[0].max_index + 1"),
        ("integer",       "DEFINE FIELD integer ON TypeIndex TYPE int VALUE $value OR 1 ASSERT $value != NONE AND $value >= 0"),
        ("smallInteger",  "DEFINE FIELD smallInteger ON TypeIndex TYPE int VALUE $value OR 1 ASSERT $value != NONE AND $value >= 0"),
        ("mediumInteger", "DEFINE FIELD mediumInteger ON TypeIndex TYPE int VALUE $value OR 1 ASSERT $value != NONE AND $value >= 0"),
        ("bigInteger",    "DEFINE FIELD bigInteger ON TypeIndex TYPE int VALUE $value OR 1 ASSERT $value != NONE AND $value >= 0"),
        ("decimal",       "DEFINE FIELD decimal ON TypeIndex TYPE decimal VALUE $value OR 1.1 ASSERT $value != NONE AND $value >= 0"),
        ("double",        "DEFINE FIELD double ON TypeIndex TYPE decimal VALUE $value OR 1.1 ASSERT $value != NONE AND $value >= 0"),
        ("float",         "DEFINE FIELD float ON TypeIndex TYPE float VALUE $value OR 1.1 ASSERT $value != NONE AND $value >= 0"),
        ("uuid",          "DEFINE FIELD uuid ON TypeIndex TYPE string VALUE $value OR rand::uuid() ASSERT $value != NONE"),
        ("char",          "DEFINE FIELD char ON TypeIndex TYPE string VALUE $value OR 'A' ASSERT string::len($value) < 256 AND $value != NONE"),
        ("string",        "DEFINE FIELD string ON TypeIndex TYPE string VALUE $value OR 'A' ASSERT string::len($value) < 256 AND $value != NONE"),
        ("text",          "DEFINE FIELD text ON TypeIndex TYPE string VALUE $value OR 'A' ASSERT $value != NONE"),
        ("mediumText",    "DEFINE FIELD mediumText ON TypeIndex TYPE string VALUE $value OR 'A' ASSERT $value != NONE"),
        ("longText",      "DEFINE FIELD longText ON TypeIndex TYPE string VALUE $value OR 'A' ASSERT $value != NONE"),
        ("date",          "DEFINE FIELD date ON TypeIndex TYPE datetime VALUE $value OR <datetime> '1970-01-01T00:00:00Z' ASSERT $value != NONE"),
        ("datetime1",     "DEFINE FIELD datetime1 ON TypeIndex TYPE datetime VALUE $value OR time::now() ASSERT $value != NONE"),
        ("datetime2",     "DEFINE FIELD datetime2 ON TypeIndex TYPE datetime VALUE time::now() ASSERT $value != NONE"),
        ("timestamp",     "DEFINE FIELD timestamp ON TypeIndex TYPE datetime VALUE $value OR <datetime> '1970-01-01T00:00:00Z' ASSERT $value != NONE"),
        ("created_at",    "DEFINE FIELD created_at ON TypeIndex TYPE datetime VALUE $value OR time::now()"),
        ("updated_at",    "DEFINE FIELD updated_at ON TypeIndex TYPE datetime VALUE time::now()"),
        ("deleted_at",    "DEFINE FIELD deleted_at ON TypeIndex TYPE datetime"),
        ("binary",        "DEFINE FIELD binary ON TypeIndex TYPE string VALUE $value OR 'A' ASSERT $value != NONE"),
        ("boolean",       "DEFINE FIELD boolean ON TypeIndex TYPE bool VALUE $value OR true ASSERT $value != NONE"),
        ("enumField",     "DEFINE FIELD enumField ON TypeIndex TYPE string VALUE $value OR 'A' ASSERT $value INSIDE ['A', 'B', 'C'] AND $value != NONE"),
        ("json",          "DEFINE FIELD json ON TypeIndex TYPE object FLEXIBLE VALUE $value OR { key: 'value' } ASSERT $value != NONE"),
        ("relation",      "DEFINE FIELD relation ON TypeIndex TYPE record<relation> | NONE VALUE $value OR NONE"),
      ])

      let indexs = if resultNode.hasKey("indexes"): resultNode["indexes"] else: resultNode["ix"]
      expectInfoEntries(indexs, @[
        ("TypeIndex_integer_index",       "DEFINE INDEX TypeIndex_integer_index ON TypeIndex FIELDS integer"),
        ("TypeIndex_smallInteger_index",  "DEFINE INDEX TypeIndex_smallInteger_index ON TypeIndex FIELDS smallInteger"),
        ("TypeIndex_mediumInteger_index", "DEFINE INDEX TypeIndex_mediumInteger_index ON TypeIndex FIELDS mediumInteger"),
        ("TypeIndex_bigInteger_index",    "DEFINE INDEX TypeIndex_bigInteger_index ON TypeIndex FIELDS bigInteger"),
        ("TypeIndex_decimal_index",       "DEFINE INDEX TypeIndex_decimal_index ON TypeIndex FIELDS decimal"),
        ("TypeIndex_double_index",        "DEFINE INDEX TypeIndex_double_index ON TypeIndex FIELDS double"),
        ("TypeIndex_float_index",         "DEFINE INDEX TypeIndex_float_index ON TypeIndex FIELDS float"),
        ("TypeIndex_uuid_unique",         "DEFINE INDEX TypeIndex_uuid_unique ON TypeIndex FIELDS uuid UNIQUE"),
        ("TypeIndex_char_index",          "DEFINE INDEX TypeIndex_char_index ON TypeIndex FIELDS char"),
        ("TypeIndex_string_index",        "DEFINE INDEX TypeIndex_string_index ON TypeIndex FIELDS string"),
        ("TypeIndex_text_index",          "DEFINE INDEX TypeIndex_text_index ON TypeIndex FIELDS text"),
        ("TypeIndex_mediumText_index",    "DEFINE INDEX TypeIndex_mediumText_index ON TypeIndex FIELDS mediumText"),
        ("TypeIndex_longText_index",      "DEFINE INDEX TypeIndex_longText_index ON TypeIndex FIELDS longText"),
        ("TypeIndex_date_index",          "DEFINE INDEX TypeIndex_date_index ON TypeIndex FIELDS date"),
        ("TypeIndex_datetime1_index",     "DEFINE INDEX TypeIndex_datetime1_index ON TypeIndex FIELDS datetime1"),
        ("TypeIndex_datetime2_index",     "DEFINE INDEX TypeIndex_datetime2_index ON TypeIndex FIELDS datetime2"),
        ("TypeIndex_timestamp_index",     "DEFINE INDEX TypeIndex_timestamp_index ON TypeIndex FIELDS timestamp"),
        ("TypeIndex_created_at_index",    "DEFINE INDEX TypeIndex_created_at_index ON TypeIndex FIELDS created_at"),
        ("TypeIndex_updated_at_index",    "DEFINE INDEX TypeIndex_updated_at_index ON TypeIndex FIELDS updated_at"),
        ("TypeIndex_deleted_at_index",    "DEFINE INDEX TypeIndex_deleted_at_index ON TypeIndex FIELDS deleted_at"),
        ("TypeIndex_binary_index",        "DEFINE INDEX TypeIndex_binary_index ON TypeIndex FIELDS binary"),
        ("TypeIndex_boolean_index",       "DEFINE INDEX TypeIndex_boolean_index ON TypeIndex FIELDS boolean"),
        ("TypeIndex_enumField_index",     "DEFINE INDEX TypeIndex_enumField_index ON TypeIndex FIELDS enumField"),
        ("TypeIndex_json_index",          "DEFINE INDEX TypeIndex_json_index ON TypeIndex FIELDS json"),
      ])

    block:
      let info = surreal.raw(""" INFO FOR TABLE TypeUnique """).info().waitFor()
      let resultNode = info[0]["result"]
      let fields = resultNode["fields"]
      expectInfoEntries(fields, @[
        ("index",         "DEFINE FIELD index ON TypeUnique TYPE int VALUE $value OR (SELECT max_index FROM _autoincrement_sequences WHERE `table` = 'TypeUnique' AND column = 'index' LIMIT 1)[0].max_index + 1"),
        ("integer",       "DEFINE FIELD integer ON TypeUnique TYPE int VALUE $value OR 1 ASSERT $value != NONE AND $value >= 0"),
        ("smallInteger",  "DEFINE FIELD smallInteger ON TypeUnique TYPE int VALUE $value OR 1 ASSERT $value != NONE AND $value >= 0"),
        ("mediumInteger", "DEFINE FIELD mediumInteger ON TypeUnique TYPE int VALUE $value OR 1 ASSERT $value != NONE AND $value >= 0"),
        ("bigInteger",    "DEFINE FIELD bigInteger ON TypeUnique TYPE int VALUE $value OR 1 ASSERT $value != NONE AND $value >= 0"),
        ("decimal",       "DEFINE FIELD decimal ON TypeUnique TYPE decimal VALUE $value OR 1.1 ASSERT $value != NONE AND $value >= 0"),
        ("double",        "DEFINE FIELD double ON TypeUnique TYPE decimal VALUE $value OR 1.1 ASSERT $value != NONE AND $value >= 0"),
        ("float",         "DEFINE FIELD float ON TypeUnique TYPE float VALUE $value OR 1.1 ASSERT $value != NONE AND $value >= 0"),
        ("uuid",          "DEFINE FIELD uuid ON TypeUnique TYPE string VALUE $value OR rand::uuid() ASSERT $value != NONE"),
        ("char",          "DEFINE FIELD char ON TypeUnique TYPE string VALUE $value OR 'A' ASSERT string::len($value) < 256 AND $value != NONE"),
        ("string",        "DEFINE FIELD string ON TypeUnique TYPE string VALUE $value OR 'A' ASSERT string::len($value) < 256 AND $value != NONE"),
        ("text",          "DEFINE FIELD text ON TypeUnique TYPE string VALUE $value OR 'A' ASSERT $value != NONE"),
        ("mediumText",    "DEFINE FIELD mediumText ON TypeUnique TYPE string VALUE $value OR 'A' ASSERT $value != NONE"),
        ("longText",      "DEFINE FIELD longText ON TypeUnique TYPE string VALUE $value OR 'A' ASSERT $value != NONE"),
        ("date",          "DEFINE FIELD date ON TypeUnique TYPE datetime VALUE $value OR <datetime> '1970-01-01T00:00:00Z' ASSERT $value != NONE"),
        ("datetime1",     "DEFINE FIELD datetime1 ON TypeUnique TYPE datetime VALUE $value OR time::now() ASSERT $value != NONE"),
        ("datetime2",     "DEFINE FIELD datetime2 ON TypeUnique TYPE datetime VALUE time::now() ASSERT $value != NONE"),
        ("timestamp",     "DEFINE FIELD timestamp ON TypeUnique TYPE datetime VALUE $value OR <datetime> '1970-01-01T00:00:00Z' ASSERT $value != NONE"),
        ("created_at",    "DEFINE FIELD created_at ON TypeUnique TYPE datetime VALUE $value OR time::now()"),
        ("updated_at",    "DEFINE FIELD updated_at ON TypeUnique TYPE datetime VALUE time::now()"),
        ("deleted_at",    "DEFINE FIELD deleted_at ON TypeUnique TYPE datetime"),
        ("binary",        "DEFINE FIELD binary ON TypeUnique TYPE string VALUE $value OR 'A' ASSERT $value != NONE"),
        ("boolean",       "DEFINE FIELD boolean ON TypeUnique TYPE bool VALUE $value OR true ASSERT $value != NONE"),
        ("enumField",     "DEFINE FIELD enumField ON TypeUnique TYPE string VALUE $value OR 'A' ASSERT $value INSIDE ['A', 'B', 'C'] AND $value != NONE"),
        ("json",          "DEFINE FIELD json ON TypeUnique TYPE object FLEXIBLE VALUE $value OR { key: 'value' } ASSERT $value != NONE"),
        ("relation",      "DEFINE FIELD relation ON TypeUnique TYPE record<relation> | NONE VALUE $value OR NONE"),
      ])

      let indexs = resultNode["indexes"]
      expectInfoEntries(indexs, @[
        ("TypeUnique_integer_unique",       "DEFINE INDEX TypeUnique_integer_unique ON TypeUnique FIELDS integer UNIQUE"),
        ("TypeUnique_smallInteger_unique",  "DEFINE INDEX TypeUnique_smallInteger_unique ON TypeUnique FIELDS smallInteger UNIQUE"),
        ("TypeUnique_mediumInteger_unique", "DEFINE INDEX TypeUnique_mediumInteger_unique ON TypeUnique FIELDS mediumInteger UNIQUE"),
        ("TypeUnique_bigInteger_unique",    "DEFINE INDEX TypeUnique_bigInteger_unique ON TypeUnique FIELDS bigInteger UNIQUE"),
        ("TypeUnique_decimal_unique",       "DEFINE INDEX TypeUnique_decimal_unique ON TypeUnique FIELDS decimal UNIQUE"),
        ("TypeUnique_double_unique",        "DEFINE INDEX TypeUnique_double_unique ON TypeUnique FIELDS double UNIQUE"),
        ("TypeUnique_float_unique",         "DEFINE INDEX TypeUnique_float_unique ON TypeUnique FIELDS float UNIQUE"),
        ("TypeUnique_uuid_unique",          "DEFINE INDEX TypeUnique_uuid_unique ON TypeUnique FIELDS uuid UNIQUE"),
        ("TypeUnique_char_unique",          "DEFINE INDEX TypeUnique_char_unique ON TypeUnique FIELDS char UNIQUE"),
        ("TypeUnique_string_unique",        "DEFINE INDEX TypeUnique_string_unique ON TypeUnique FIELDS string UNIQUE"),
        ("TypeUnique_text_unique",          "DEFINE INDEX TypeUnique_text_unique ON TypeUnique FIELDS text UNIQUE"),
        ("TypeUnique_mediumText_unique",    "DEFINE INDEX TypeUnique_mediumText_unique ON TypeUnique FIELDS mediumText UNIQUE"),
        ("TypeUnique_longText_unique",      "DEFINE INDEX TypeUnique_longText_unique ON TypeUnique FIELDS longText UNIQUE"),
        ("TypeUnique_date_unique",          "DEFINE INDEX TypeUnique_date_unique ON TypeUnique FIELDS date UNIQUE"),
        ("TypeUnique_datetime1_unique",     "DEFINE INDEX TypeUnique_datetime1_unique ON TypeUnique FIELDS datetime1 UNIQUE"),
        ("TypeUnique_datetime2_unique",     "DEFINE INDEX TypeUnique_datetime2_unique ON TypeUnique FIELDS datetime2 UNIQUE"),
        ("TypeUnique_timestamp_unique",     "DEFINE INDEX TypeUnique_timestamp_unique ON TypeUnique FIELDS timestamp UNIQUE"),
        ("TypeUnique_created_at_index",     "DEFINE INDEX TypeUnique_created_at_index ON TypeUnique FIELDS created_at"),
        ("TypeUnique_updated_at_index",     "DEFINE INDEX TypeUnique_updated_at_index ON TypeUnique FIELDS updated_at"),
        ("TypeUnique_deleted_at_index",     "DEFINE INDEX TypeUnique_deleted_at_index ON TypeUnique FIELDS deleted_at"),
        ("TypeUnique_binary_unique",        "DEFINE INDEX TypeUnique_binary_unique ON TypeUnique FIELDS binary UNIQUE"),
        ("TypeUnique_boolean_unique",       "DEFINE INDEX TypeUnique_boolean_unique ON TypeUnique FIELDS boolean UNIQUE"),
        ("TypeUnique_enumField_unique",     "DEFINE INDEX TypeUnique_enumField_unique ON TypeUnique FIELDS enumField UNIQUE"),
        ("TypeUnique_json_unique",          "DEFINE INDEX TypeUnique_json_unique ON TypeUnique FIELDS json UNIQUE"),
      ])


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

      surreal.table("test").insert(%*{"name": "alice"}).waitFor()

      var alice = surreal.table("test").first().waitFor().get()
      let aliceId = SurrealId.new(alice["id"].getStr())
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

      surreal.table("test").insert(%*{"name": "alice"}).waitFor()

      var alice = surreal.table("test").first().waitFor().get()
      let aliceId = SurrealId.new(alice["id"].getStr())
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
      let resultNode = info[0]["result"]
      let fields = resultNode["fields"]
      expectInfoEntries(fields, @[
        ("index",         "DEFINE FIELD index ON TypeIndex TYPE int VALUE $value OR (SELECT max_index FROM _autoincrement_sequences WHERE `table` = 'TypeIndex' AND column = 'index' LIMIT 1)[0].max_index + 1"),
        ("integer",       "DEFINE FIELD integer ON TypeIndex TYPE int VALUE $value OR 1 ASSERT $value != NONE AND $value >= 0"),
        ("smallInteger",  "DEFINE FIELD smallInteger ON TypeIndex TYPE int VALUE $value OR 1 ASSERT $value != NONE AND $value >= 0"),
        ("mediumInteger", "DEFINE FIELD mediumInteger ON TypeIndex TYPE int VALUE $value OR 1 ASSERT $value != NONE AND $value >= 0"),
        ("bigInteger",    "DEFINE FIELD bigInteger ON TypeIndex TYPE int VALUE $value OR 1 ASSERT $value != NONE AND $value >= 0"),
        ("decimal",       "DEFINE FIELD decimal ON TypeIndex TYPE decimal VALUE $value OR 1.1 ASSERT $value != NONE AND $value >= 0"),
        ("double",        "DEFINE FIELD double ON TypeIndex TYPE decimal VALUE $value OR 1.1 ASSERT $value != NONE AND $value >= 0"),
        ("float",         "DEFINE FIELD float ON TypeIndex TYPE float VALUE $value OR 1.1 ASSERT $value != NONE AND $value >= 0"),
        ("uuid",          "DEFINE FIELD uuid ON TypeIndex TYPE string VALUE $value OR rand::uuid() ASSERT $value != NONE"),
        ("char",          "DEFINE FIELD char ON TypeIndex TYPE string VALUE $value OR 'A' ASSERT string::len($value) < 256 AND $value != NONE"),
        ("string",        "DEFINE FIELD string ON TypeIndex TYPE string VALUE $value OR 'A' ASSERT string::len($value) < 256 AND $value != NONE"),
        ("text",          "DEFINE FIELD text ON TypeIndex TYPE string VALUE $value OR 'A' ASSERT $value != NONE"),
        ("mediumText",    "DEFINE FIELD mediumText ON TypeIndex TYPE string VALUE $value OR 'A' ASSERT $value != NONE"),
        ("longText",      "DEFINE FIELD longText ON TypeIndex TYPE string VALUE $value OR 'A' ASSERT $value != NONE"),
        ("date",          "DEFINE FIELD date ON TypeIndex TYPE datetime VALUE $value OR <datetime> '1970-01-01T00:00:00Z' ASSERT $value != NONE"),
        ("datetime1",     "DEFINE FIELD datetime1 ON TypeIndex TYPE datetime VALUE $value OR time::now() ASSERT $value != NONE"),
        ("datetime2",     "DEFINE FIELD datetime2 ON TypeIndex TYPE datetime VALUE time::now() ASSERT $value != NONE"),
        ("timestamp",     "DEFINE FIELD timestamp ON TypeIndex TYPE datetime VALUE $value OR <datetime> '1970-01-01T00:00:00Z' ASSERT $value != NONE"),
        ("created_at",    "DEFINE FIELD created_at ON TypeIndex TYPE datetime VALUE $value OR time::now()"),
        ("updated_at",    "DEFINE FIELD updated_at ON TypeIndex TYPE datetime VALUE time::now()"),
        ("deleted_at",    "DEFINE FIELD deleted_at ON TypeIndex TYPE datetime"),
        ("binary",        "DEFINE FIELD binary ON TypeIndex TYPE string VALUE $value OR 'A' ASSERT $value != NONE"),
        ("boolean",       "DEFINE FIELD boolean ON TypeIndex TYPE bool VALUE $value OR true ASSERT $value != NONE"),
        ("enumField",     "DEFINE FIELD enumField ON TypeIndex TYPE string VALUE $value OR 'A' ASSERT $value INSIDE ['A', 'B', 'C'] AND $value != NONE"),
        ("json",          "DEFINE FIELD json ON TypeIndex TYPE object FLEXIBLE VALUE $value OR { key: 'value' } ASSERT $value != NONE"),
        ("relation",      "DEFINE FIELD relation ON TypeIndex TYPE record<relation> | NONE VALUE $value OR NONE"),
      ])

      let indexs = resultNode["indexes"]
      expectInfoEntries(indexs, @[
        ("TypeIndex_integer_index",       "DEFINE INDEX TypeIndex_integer_index ON TypeIndex FIELDS integer"),
        ("TypeIndex_smallInteger_index",  "DEFINE INDEX TypeIndex_smallInteger_index ON TypeIndex FIELDS smallInteger"),
        ("TypeIndex_mediumInteger_index", "DEFINE INDEX TypeIndex_mediumInteger_index ON TypeIndex FIELDS mediumInteger"),
        ("TypeIndex_bigInteger_index",    "DEFINE INDEX TypeIndex_bigInteger_index ON TypeIndex FIELDS bigInteger"),
        ("TypeIndex_decimal_index",       "DEFINE INDEX TypeIndex_decimal_index ON TypeIndex FIELDS decimal"),
        ("TypeIndex_double_index",        "DEFINE INDEX TypeIndex_double_index ON TypeIndex FIELDS double"),
        ("TypeIndex_float_index",         "DEFINE INDEX TypeIndex_float_index ON TypeIndex FIELDS float"),
        ("TypeIndex_uuid_unique",         "DEFINE INDEX TypeIndex_uuid_unique ON TypeIndex FIELDS uuid UNIQUE"),
        ("TypeIndex_char_index",          "DEFINE INDEX TypeIndex_char_index ON TypeIndex FIELDS char"),
        ("TypeIndex_string_index",        "DEFINE INDEX TypeIndex_string_index ON TypeIndex FIELDS string"),
        ("TypeIndex_text_index",          "DEFINE INDEX TypeIndex_text_index ON TypeIndex FIELDS text"),
        ("TypeIndex_mediumText_index",    "DEFINE INDEX TypeIndex_mediumText_index ON TypeIndex FIELDS mediumText"),
        ("TypeIndex_longText_index",      "DEFINE INDEX TypeIndex_longText_index ON TypeIndex FIELDS longText"),
        ("TypeIndex_date_index",          "DEFINE INDEX TypeIndex_date_index ON TypeIndex FIELDS date"),
        ("TypeIndex_datetime1_index",     "DEFINE INDEX TypeIndex_datetime1_index ON TypeIndex FIELDS datetime1"),
        ("TypeIndex_datetime2_index",     "DEFINE INDEX TypeIndex_datetime2_index ON TypeIndex FIELDS datetime2"),
        ("TypeIndex_timestamp_index",     "DEFINE INDEX TypeIndex_timestamp_index ON TypeIndex FIELDS timestamp"),
        ("TypeIndex_created_at_index",    "DEFINE INDEX TypeIndex_created_at_index ON TypeIndex FIELDS created_at"),
        ("TypeIndex_updated_at_index",    "DEFINE INDEX TypeIndex_updated_at_index ON TypeIndex FIELDS updated_at"),
        ("TypeIndex_deleted_at_index",    "DEFINE INDEX TypeIndex_deleted_at_index ON TypeIndex FIELDS deleted_at"),
        ("TypeIndex_binary_index",        "DEFINE INDEX TypeIndex_binary_index ON TypeIndex FIELDS binary"),
        ("TypeIndex_boolean_index",       "DEFINE INDEX TypeIndex_boolean_index ON TypeIndex FIELDS boolean"),
        ("TypeIndex_enumField_index",     "DEFINE INDEX TypeIndex_enumField_index ON TypeIndex FIELDS enumField"),
        ("TypeIndex_json_index",          "DEFINE INDEX TypeIndex_json_index ON TypeIndex FIELDS json"),
      ])

    block:
      let info = surreal.raw(""" INFO FOR TABLE TypeUnique """).info().waitFor()
      let resultNode = info[0]["result"]
      let fields = resultNode["fields"]
      expectInfoEntries(fields, @[
        ("index",         "DEFINE FIELD index ON TypeUnique TYPE int VALUE $value OR (SELECT max_index FROM _autoincrement_sequences WHERE `table` = 'TypeUnique' AND column = 'index' LIMIT 1)[0].max_index + 1"),
        ("integer",       "DEFINE FIELD integer ON TypeUnique TYPE int VALUE $value OR 1 ASSERT $value != NONE AND $value >= 0"),
        ("smallInteger",  "DEFINE FIELD smallInteger ON TypeUnique TYPE int VALUE $value OR 1 ASSERT $value != NONE AND $value >= 0"),
        ("mediumInteger", "DEFINE FIELD mediumInteger ON TypeUnique TYPE int VALUE $value OR 1 ASSERT $value != NONE AND $value >= 0"),
        ("bigInteger",    "DEFINE FIELD bigInteger ON TypeUnique TYPE int VALUE $value OR 1 ASSERT $value != NONE AND $value >= 0"),
        ("decimal",       "DEFINE FIELD decimal ON TypeUnique TYPE decimal VALUE $value OR 1.1 ASSERT $value != NONE AND $value >= 0"),
        ("double",        "DEFINE FIELD double ON TypeUnique TYPE decimal VALUE $value OR 1.1 ASSERT $value != NONE AND $value >= 0"),
        ("float",         "DEFINE FIELD float ON TypeUnique TYPE float VALUE $value OR 1.1 ASSERT $value != NONE AND $value >= 0"),
        ("uuid",          "DEFINE FIELD uuid ON TypeUnique TYPE string VALUE $value OR rand::uuid() ASSERT $value != NONE"),
        ("char",          "DEFINE FIELD char ON TypeUnique TYPE string VALUE $value OR 'A' ASSERT string::len($value) < 256 AND $value != NONE"),
        ("string",        "DEFINE FIELD string ON TypeUnique TYPE string VALUE $value OR 'A' ASSERT string::len($value) < 256 AND $value != NONE"),
        ("text",          "DEFINE FIELD text ON TypeUnique TYPE string VALUE $value OR 'A' ASSERT $value != NONE"),
        ("mediumText",    "DEFINE FIELD mediumText ON TypeUnique TYPE string VALUE $value OR 'A' ASSERT $value != NONE"),
        ("longText",      "DEFINE FIELD longText ON TypeUnique TYPE string VALUE $value OR 'A' ASSERT $value != NONE"),
        ("date",          "DEFINE FIELD date ON TypeUnique TYPE datetime VALUE $value OR <datetime> '1970-01-01T00:00:00Z' ASSERT $value != NONE"),
        ("datetime1",     "DEFINE FIELD datetime1 ON TypeUnique TYPE datetime VALUE $value OR time::now() ASSERT $value != NONE"),
        ("datetime2",     "DEFINE FIELD datetime2 ON TypeUnique TYPE datetime VALUE time::now() ASSERT $value != NONE"),
        ("timestamp",     "DEFINE FIELD timestamp ON TypeUnique TYPE datetime VALUE $value OR <datetime> '1970-01-01T00:00:00Z' ASSERT $value != NONE"),
        ("created_at",    "DEFINE FIELD created_at ON TypeUnique TYPE datetime VALUE $value OR time::now()"),
        ("updated_at",    "DEFINE FIELD updated_at ON TypeUnique TYPE datetime VALUE time::now()"),
        ("deleted_at",    "DEFINE FIELD deleted_at ON TypeUnique TYPE datetime"),
        ("binary",        "DEFINE FIELD binary ON TypeUnique TYPE string VALUE $value OR 'A' ASSERT $value != NONE"),
        ("boolean",       "DEFINE FIELD boolean ON TypeUnique TYPE bool VALUE $value OR true ASSERT $value != NONE"),
        ("enumField",     "DEFINE FIELD enumField ON TypeUnique TYPE string VALUE $value OR 'A' ASSERT $value INSIDE ['A', 'B', 'C'] AND $value != NONE"),
        ("json",          "DEFINE FIELD json ON TypeUnique TYPE object FLEXIBLE VALUE $value OR { key: 'value' } ASSERT $value != NONE"),
        ("relation",      "DEFINE FIELD relation ON TypeUnique TYPE record<relation> | NONE VALUE $value OR NONE"),
      ])

      let indexs = if resultNode.hasKey("indexes"): resultNode["indexes"] else: resultNode["ix"]
      expectInfoEntries(indexs, @[
        ("TypeUnique_integer_unique",       "DEFINE INDEX TypeUnique_integer_unique ON TypeUnique FIELDS integer UNIQUE"),
        ("TypeUnique_smallInteger_unique",  "DEFINE INDEX TypeUnique_smallInteger_unique ON TypeUnique FIELDS smallInteger UNIQUE"),
        ("TypeUnique_mediumInteger_unique", "DEFINE INDEX TypeUnique_mediumInteger_unique ON TypeUnique FIELDS mediumInteger UNIQUE"),
        ("TypeUnique_bigInteger_unique",    "DEFINE INDEX TypeUnique_bigInteger_unique ON TypeUnique FIELDS bigInteger UNIQUE"),
        ("TypeUnique_decimal_unique",       "DEFINE INDEX TypeUnique_decimal_unique ON TypeUnique FIELDS decimal UNIQUE"),
        ("TypeUnique_double_unique",        "DEFINE INDEX TypeUnique_double_unique ON TypeUnique FIELDS double UNIQUE"),
        ("TypeUnique_float_unique",         "DEFINE INDEX TypeUnique_float_unique ON TypeUnique FIELDS float UNIQUE"),
        ("TypeUnique_uuid_unique",          "DEFINE INDEX TypeUnique_uuid_unique ON TypeUnique FIELDS uuid UNIQUE"),
        ("TypeUnique_char_unique",          "DEFINE INDEX TypeUnique_char_unique ON TypeUnique FIELDS char UNIQUE"),
        ("TypeUnique_string_unique",        "DEFINE INDEX TypeUnique_string_unique ON TypeUnique FIELDS string UNIQUE"),
        ("TypeUnique_text_unique",          "DEFINE INDEX TypeUnique_text_unique ON TypeUnique FIELDS text UNIQUE"),
        ("TypeUnique_mediumText_unique",    "DEFINE INDEX TypeUnique_mediumText_unique ON TypeUnique FIELDS mediumText UNIQUE"),
        ("TypeUnique_longText_unique",      "DEFINE INDEX TypeUnique_longText_unique ON TypeUnique FIELDS longText UNIQUE"),
        ("TypeUnique_date_unique",          "DEFINE INDEX TypeUnique_date_unique ON TypeUnique FIELDS date UNIQUE"),
        ("TypeUnique_datetime1_unique",     "DEFINE INDEX TypeUnique_datetime1_unique ON TypeUnique FIELDS datetime1 UNIQUE"),
        ("TypeUnique_datetime2_unique",     "DEFINE INDEX TypeUnique_datetime2_unique ON TypeUnique FIELDS datetime2 UNIQUE"),
        ("TypeUnique_timestamp_unique",     "DEFINE INDEX TypeUnique_timestamp_unique ON TypeUnique FIELDS timestamp UNIQUE"),
        ("TypeUnique_created_at_index",     "DEFINE INDEX TypeUnique_created_at_index ON TypeUnique FIELDS created_at"),
        ("TypeUnique_updated_at_index",     "DEFINE INDEX TypeUnique_updated_at_index ON TypeUnique FIELDS updated_at"),
        ("TypeUnique_deleted_at_index",     "DEFINE INDEX TypeUnique_deleted_at_index ON TypeUnique FIELDS deleted_at"),
        ("TypeUnique_binary_unique",        "DEFINE INDEX TypeUnique_binary_unique ON TypeUnique FIELDS binary UNIQUE"),
        ("TypeUnique_boolean_unique",       "DEFINE INDEX TypeUnique_boolean_unique ON TypeUnique FIELDS boolean UNIQUE"),
        ("TypeUnique_enumField_unique",     "DEFINE INDEX TypeUnique_enumField_unique ON TypeUnique FIELDS enumField UNIQUE"),
        ("TypeUnique_json_unique",          "DEFINE INDEX TypeUnique_json_unique ON TypeUnique FIELDS json UNIQUE"),
      ])


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
