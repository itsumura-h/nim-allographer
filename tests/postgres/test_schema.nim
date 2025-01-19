discard """
  cmd: "nim c -d:reset -r $file"
"""

import std/unittest
import std/asyncdispatch
import std/json
import std/options
import ../../src/allographer/schema_builder
import ../../src/allographer/query_builder
import ../connections
import ../clear_tables


let rdb = postgres

suite("PostgreSQL create table"):
  test("create table"):
    rdb.create(
      table("IntRelation", [
        Column.increments("id")
      ]),
      table("StrRelation", [
        Column.uuid("uuid")
      ]),
      table("TypeIndex", [
        Column.increments("id"),
        Column.integer("integer").unsigned().index().default(1),
        Column.smallInteger("smallInteger").unsigned().index().default(1),
        Column.mediumInteger("mediumInteger").unsigned().index().default(1),
        Column.bigInteger("bigInteger").unsigned().index().default(1),
        Column.decimal("decimal", 10, 3).unsigned().index().default(1.1),
        Column.double("double", 10, 3).unsigned().index().default(1.1),
        Column.float("float").unsigned().index().default(1.1),
        Column.uuid("uuid").index().default("A"),
        Column.char("char", 255).index().default("A"),
        Column.string("string").index().default("A"),
        Column.text("text").index().default("A"),
        Column.mediumText("mediumText").index().default("A"),
        Column.longText("longText").index().default("A"),
        Column.date("date").index().default(),
        Column.datetime("datetime").index().default(),
        Column.time("time").index().default(),
        Column.timestamp("timestamp").index().default(),
        Column.timestamps(),
        Column.softDelete(),
        Column.binary("binary").index().default("A"),
        Column.boolean("boolean").index().default(true),
        Column.enumField("enumField", ["A", "B", "C"]).index().default("A"),
        Column.json("json").index().default(%*{"key":"value"}),
        Column.foreign("int_relation_id").reference("id").onTable("IntRelation").onDelete(SET_NULL),
        Column.strForeign("str_relation_id").reference("uuid").onTable("StrRelation").onDelete(SET_NULL)
      ]),
      table("TypeUnique", [
        Column.increments("id"),
        Column.integer("integer").unsigned().unique().index().default(1),
        Column.smallInteger("smallInteger").unsigned().unique().index().default(1),
        Column.mediumInteger("mediumInteger").unsigned().unique().index().default(1),
        Column.bigInteger("bigInteger").unsigned().unique().index().default(1),
        Column.decimal("decimal", 10, 3).unsigned().unique().index().default(1.1),
        Column.double("double", 10, 3).unsigned().unique().index().default(1.1),
        Column.float("float").unsigned().unique().index().default(1.1),
        Column.uuid("uuid").unique().index().default("A"),
        Column.char("char", 255).unique().index().default("A"),
        Column.string("string").unique().index().default("A"),
        Column.text("text").unique().index().default("A"),
        Column.mediumText("mediumText").unique().index().default("A"),
        Column.longText("longText").unique().index().default("A"),
        Column.date("date").unique().index().default(),
        Column.datetime("datetime").unique().index().default(),
        Column.time("time").unique().index().default(),
        Column.timestamp("timestamp").unique().index().default(),
        Column.timestamps(),
        Column.softDelete(),
        Column.binary("binary").unique().index().default("A"),
        Column.boolean("boolean").unique().index().default(true),
        Column.enumField("enumField", ["A", "B", "C"]).unique().index().default("A"),
        Column.json("json").unique().index().default(%*{"key":"value"}),
        Column.foreign("int_relation_id").reference("id").onTable("IntRelation").onDelete(SET_NULL),
        Column.strForeign("str_relation_id").reference("uuid").onTable("StrRelation").onDelete(SET_NULL)
      ])
    )


  test("change columns"):
    rdb.alter(
      table("TypeIndex", [
        Column.integer("integer").unsigned().index().default(1).change(),
        Column.smallInteger("smallInteger").unsigned().index().default(1).change(),
        Column.mediumInteger("mediumInteger").unsigned().index().default(1).change(),
        Column.bigInteger("bigInteger").unsigned().index().default(1).change(),
        Column.decimal("decimal", 10, 3).unsigned().index().default(1.1).change(),
        Column.double("double", 10, 3).unsigned().index().default(1.1).change(),
        Column.float("float").unsigned().index().default(1.1).change(),
        Column.uuid("uuid").index().default("A").change(),
        Column.char("char", 255).index().default("A").change(),
        Column.string("string").index().default("A").change(),
        Column.text("text").index().default("A").change(),
        Column.mediumText("mediumText").index().default("A").change(),
        Column.longText("longText").index().default("A").change(),
        Column.date("date").index().default().change(),
        Column.datetime("datetime").index().default().change(),
        Column.time("time").index().default().change(),
        Column.timestamp("timestamp").index().default().change(),
        Column.binary("binary").index().default("A").change(),
        Column.boolean("boolean").index().default(true).change(),
        Column.enumField("enumField", ["A", "B", "C"]).index().default("A").change(),
        Column.json("json").index().default(%*{"key":"value"}).change(),
      ]),
      table("TypeUnique", [
        Column.integer("integer").unsigned().unique().index().default(1).change(),
        Column.smallInteger("smallInteger").unsigned().unique().index().default(1).change(),
        Column.mediumInteger("mediumInteger").unsigned().unique().index().default(1).change(),
        Column.bigInteger("bigInteger").unsigned().unique().index().default(1).change(),
        Column.decimal("decimal", 10, 3).unsigned().unique().index().default(1.1).change(),
        Column.double("double", 10, 3).unsigned().unique().index().default(1.1).change(),
        Column.float("float").unsigned().unique().index().default(1.1).change(),
        Column.uuid("uuid").unique().index().default("A").change(),
        Column.char("char", 255).unique().index().default("A").change(),
        Column.string("string").unique().index().default("A").change(),
        Column.text("text").unique().index().default("A").change(),
        Column.mediumText("mediumText").unique().index().default("A").change(),
        Column.longText("longText").unique().index().default("A").change(),
        Column.date("date").unique().index().default().change(),
        Column.datetime("datetime").unique().index().default().change(),
        Column.time("time").unique().index().default().change(),
        Column.timestamp("timestamp").unique().index().default().change(),
        Column.binary("binary").unique().index().default("A").change(),
        Column.boolean("boolean").unique().index().default(true).change(),
        Column.enumField("enumField", ["A", "B", "C"]).unique().index().default("A").change(),
        Column.json("json").unique().index().default(%*{"key":"value"}).change(),
      ])
    )


suite($rdb & " alter table"):
  setup:
    rdb.create(
      table("IntRelation", [
        Column.increments("id"),
      ]),
      table("StrRelation", [
        Column.uuid("uuid"),
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


  test("add columns"):
    rdb.alter(
      table("TypeIndex", [
        Column.increments("id").add(),
        Column.integer("integer").unsigned().index().default(1).add(),
        Column.smallInteger("smallInteger").unsigned().index().default(1).add(),
        Column.mediumInteger("mediumInteger").unsigned().index().default(1).add(),
        Column.bigInteger("bigInteger").unsigned().index().default(1).add(),
        Column.decimal("decimal", 10, 3).unsigned().index().default(1.1).add(),
        Column.double("double", 10, 3).unsigned().index().default(1.1).add(),
        Column.float("float").unsigned().index().default(1.1).add(),
        Column.uuid("uuid").index().default("A").add(),
        Column.char("char", 255).index().default("A").add(),
        Column.string("string").index().default("A").add(),
        Column.text("text").index().default("A").add(),
        Column.mediumText("mediumText").index().default("A").add(),
        Column.longText("longText").index().default("A").add(),
        Column.date("date").index().default().add(),
        Column.datetime("datetime").index().default(),
        Column.time("time").index().default().add(),
        Column.timestamp("timestamp").index().default().add(),
        Column.timestamps().add(),
        Column.softDelete().add(),
        Column.binary("binary").index().default("A").add(),
        Column.boolean("boolean").index().default(true).add(),
        Column.enumField("enumField", ["A", "B", "C"]).index().default("A").add(),
        Column.json("json").index().default(%*{"key":"value"}).add(),
        Column.foreign("int_relation_id").reference("id").onTable("IntRelation").onDelete(SET_NULL).add(),
        Column.strForeign("str_relation_id").reference("uuid").onTable("StrRelation").onDelete(SET_NULL).add()
      ]),
      table("TypeUnique", [
        Column.increments("id").add(),
        Column.integer("integer").unsigned().unique().index().default(1).add(),
        Column.smallInteger("smallInteger").unsigned().unique().index().default(1).add(),
        Column.mediumInteger("mediumInteger").unsigned().unique().index().default(1).add(),
        Column.bigInteger("bigInteger").unsigned().unique().index().default(1).add(),
        Column.decimal("decimal", 10, 3).unsigned().unique().index().default(1.1).add(),
        Column.double("double", 10, 3).unsigned().unique().index().default(1.1).add(),
        Column.float("float").unsigned().unique().index().default(1.1).add(),
        Column.uuid("uuid").unique().index().default("A").add(),
        Column.char("char", 255).unique().index().default("A").add(),
        Column.string("string").unique().index().default("A").add(),
        Column.text("text").unique().index().default("A").add(),
        Column.mediumText("mediumText").unique().index().default("A").add(),
        Column.longText("longText").unique().index().default("A").add(),
        Column.date("date").unique().index().default().add(),
        Column.datetime("datetime").unique().index().default().add(),
        Column.time("time").unique().index().default().add(),
        Column.timestamp("timestamp").unique().index().default().add(),
        Column.timestamps().add(),
        Column.softDelete().add(),
        Column.binary("binary").unique().index().default("A").add(),
        Column.boolean("boolean").unique().index().default(true).add(),
        Column.enumField("enumField", ["A", "B", "C"]).unique().index().default("A").add(),
        Column.json("json").unique().index().default(%*{"key":"value"}).add()
      ])
    )


  test("rename column"):
    rdb.alter(
      table("TypeIndex", [
        Column.renameColumn("num", "num2"),
        Column.renameColumn("str", "str2"),
      ])
    )

    let columns = rdb.table("TypeIndex").columns().waitFor
    check not columns.contains("num")
    check columns.contains("num2")
    check not columns.contains("str")
    check columns.contains("str2")


  test("drop column"):
    rdb.alter(
      table("TypeIndex", [
        Column.dropColumn("str")
      ])
    )

    let columns = rdb.table("TypeIndex").columns().waitFor
    check not columns.contains("str")


  test("rename table"):
    rdb.drop(
      table("TypeIndex_renamed")
    )
    rdb.table("TypeIndex").insert(%*{"num":1, "str": "a"}).waitFor

    rdb.alter(
      table("TypeIndex").renameTo("TypeIndex_renamed")
    )

    var res:Option[JsonNode]
    try:
      res = rdb.table("TypeIndex").first().waitFor
      check not res.isSome
    except CatchableError:
      check true

    res = rdb.table("TypeIndex_renamed").first().waitFor
    check res.isSome


  test("drop table"):
    rdb.create(
      table("TypeIndex", [
        Column.integer("num")
      ])
    )

    rdb.drop(
      table("TypeIndex")
    )
    
    var res:Option[JsonNode]
    try:
      res = rdb.table("TypeIndex").first().waitFor
      check not res.isSome
    except CatchableError:
      check true


suite($rdb & " primary"):
  test("primary key"):
    rdb.create([
      table("relation", [
        Column.increments("id"),
      ]),
      table("TypeIndex", @[
          Column.integer("index1"),
          Column.integer("index2"),
          Column.string("string"),
          Column.foreign("relation_id").reference("id").onTable("relation").onDelete(SET_NULL)
        ],
        primary = @["index1", "index2"]
      )
    ])


suite("Comment"):
  test("column comment"):
    rdb.create(
      table("Comment", [
        Column.integer("index1").comment("index1 comment"),
        Column.string("string").comment("string comment")
      ])
    )


clearTables(rdb).waitFor()
