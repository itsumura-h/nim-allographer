discard """
  cmd: "nim c -d:reset -r $file"
"""

import std/unittest
import std/asyncdispatch
import std/json
import std/options
import ../../../src/allographer/schema_builder
import ../../../src/allographer/query_builder
import ../../connections
import ../../clear_tables


let rdb = mysql

suite("MySQL create table"):
  test("create table"):
    rdb.create(
      table("IntRelation", [
        Column.increments("id")
      ]),
      table("StrRelation", [
        Column.uuid("uuid")
      ]),
      # text, binary, json column can't use default value and index
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
        Column.text("text"),
        Column.mediumText("mediumText"),
        Column.longText("longText"),
        Column.date("date").index().default(),
        Column.datetime("datetime").index().default(),
        Column.time("time").index().default(),
        Column.timestamp("timestamp").index().default(),
        Column.timestamps(),
        Column.softDelete(),
        Column.binary("binary"),
        Column.boolean("boolean").index().default(true),
        Column.enumField("enumField", ["A", "B", "C"]).index().default("A"),
        Column.json("json"),
        Column.foreign("int_relation_id").reference("id").onTable("IntRelation").onDelete(SET_NULL),
        Column.strForeign("str_relation_id").reference("uuid").onTable("StrRelation").onDelete(SET_NULL)
      ]),
      # text, binary, json column can't use default value, index and unique
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
        Column.text("text"),
        Column.mediumText("mediumText"),
        Column.longText("longText"),
        Column.date("date").unique().index().default(),
        Column.datetime("datetime").unique().index().default(),
        Column.time("time").unique().index().default(),
        Column.timestamp("timestamp").unique().index().default(),
        Column.timestamps(),
        Column.softDelete(),
        Column.binary("binary"),
        Column.boolean("boolean").unique().index().default(true),
        Column.enumField("enumField", ["A", "B", "C"]).unique().index().default("A"),
        Column.json("json"),
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
        Column.text("text").change(),
        Column.mediumText("mediumText").change(),
        Column.longText("longText").change(),
        Column.date("date").index().default().change(),
        Column.datetime("datetime").index().default().change(),
        Column.time("time").index().default().change(),
        Column.timestamp("timestamp").index().default().change(),
        Column.binary("binary").change(),
        Column.boolean("boolean").index().default(true).change(),
        Column.enumField("enumField", ["A", "B", "C"]).index().default("A").change(),
        Column.json("json").change(),
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
        Column.text("text").change(),
        Column.mediumText("mediumText").change(),
        Column.longText("longText").change(),
        Column.date("date").unique().index().default().change(),
        Column.datetime("datetime").unique().index().default().change(),
        Column.time("time").unique().index().default().change(),
        Column.timestamp("timestamp").unique().index().default().change(),
        Column.binary("binary").change(),
        Column.boolean("boolean").unique().index().default(true).change(),
        Column.enumField("enumField", ["A", "B", "C"]).unique().index().default("A").change(),
        Column.json("json").change(),
      ])
    )


suite("error in text, blob, json column for default, index and unique"):
  suite("create table"):
    test("text"):
      expect DbError:
        rdb.create(
          table("TypeIndex", [
            Column.text("text").default("A"),
          ])
        )
      expect DbError:
        rdb.create(
          table("TypeIndex", [
            Column.text("text").index(),
          ])
        )
      expect DbError:
        rdb.create(
          table("TypeIndex", [
            Column.text("text").unique(),
          ])
        )

    test("mediumText"):
      expect DbError:
        rdb.create(
          table("TypeIndex", [
            Column.mediumText("mediumText").default("A"),
          ])
        )
      expect DbError:
        rdb.create(
          table("TypeIndex", [
            Column.mediumText("mediumText").index(),
          ])
        )
      expect DbError:
        rdb.create(
          table("TypeIndex", [
            Column.mediumText("mediumText").unique(),
          ])
        )

    test("longText"):
      expect DbError:
        rdb.create(
          table("TypeIndex", [
            Column.longText("longText").default("A"),
          ])
        )
      expect DbError:
        rdb.create(
          table("TypeIndex", [
            Column.longText("longText").index(),
          ])
        )
      expect DbError:
        rdb.create(
          table("TypeIndex", [
            Column.longText("longText").unique(),
          ])
        )

    test("binary"):
      expect DbError:
        rdb.create(
          table("TypeIndex", [
            Column.binary("binary").default("A"),
          ])
        )
      expect DbError:
        rdb.create(
          table("TypeIndex", [
            Column.binary("binary").index(),
          ])
        )
      expect DbError:
        rdb.create(
          table("TypeIndex", [
            Column.binary("binary").unique(),
          ])
        )

    test("json"):
      expect DbError:
        rdb.create(
          table("TypeIndex", [
            Column.json("json").default(%*{"key": "value"}),
          ])
        )
      expect DbError:
        rdb.create(
          table("TypeIndex", [
            Column.json("json").index(),
          ])
        )
      expect DbError:
        rdb.create(
          table("TypeIndex", [
            Column.json("json").unique(),
          ])
        )


  suite("add column"):
    test("text"):
      expect DbError:
        rdb.alter(
          table("TypeIndex", [
            Column.text("text").default("A").add(),
          ])
        )
      expect DbError:
        rdb.alter(
          table("TypeIndex", [
            Column.text("text").index().add(),
          ])
        )
      expect DbError:
        rdb.alter(
          table("TypeIndex", [
            Column.text("text").unique().add(),
          ])
        )

    test("mediumText"):
      expect DbError:
        rdb.alter(
          table("TypeIndex", [
            Column.mediumText("mediumText").default("A").add(),
          ])
        )
      expect DbError:
        rdb.create(
          table("TypeIndex", [
            Column.mediumText("mediumText").index().add(),
          ])
        )
      expect DbError:
        rdb.create(
          table("TypeIndex", [
            Column.mediumText("mediumText").unique().add(),
          ])
        )

    test("longText"):
      expect DbError:
        rdb.alter(
          table("TypeIndex", [
            Column.longText("longText").default("A").add(),
          ])
        )
      expect DbError:
        rdb.alter(
          table("TypeIndex", [
            Column.longText("longText").index().add(),
          ])
        )
      expect DbError:
        rdb.alter(
          table("TypeIndex", [
            Column.longText("longText").unique().add(),
          ])
        )

    test("binary"):
      expect DbError:
        rdb.alter(
          table("TypeIndex", [
            Column.binary("binary").default("A").add(),
          ])
        )
      expect DbError:
        rdb.alter(
          table("TypeIndex", [
            Column.binary("binary").index().add(),
          ])
        )
      expect DbError:
        rdb.alter(
          table("TypeIndex", [
            Column.binary("binary").unique().add(),
          ])
        )

    test("json"):
      expect DbError:
        rdb.alter(
          table("TypeIndex", [
            Column.json("json").default(%*{"key": "value"}).add(),
          ])
        )
      expect DbError:
        rdb.alter(
          table("TypeIndex", [
            Column.json("json").index().add(),
          ])
        )
      expect DbError:
        rdb.alter(
          table("TypeIndex", [
            Column.json("json").unique().add(),
          ])
        )


  suite("change column"):
    test("text"):
      expect DbError:
        rdb.alter(
          table("TypeIndex", [
            Column.text("text").default("A").change(),
          ])
        )
      expect DbError:
        rdb.alter(
          table("TypeIndex", [
            Column.text("text").index().change(),
          ])
        )
      expect DbError:
        rdb.alter(
          table("TypeIndex", [
            Column.text("text").unique().change(),
          ])
        )

    test("mediumText"):
      expect DbError:
        rdb.alter(
          table("TypeIndex", [
            Column.mediumText("mediumText").default("A").change(),
          ])
        )
      expect DbError:
        rdb.alter(
          table("TypeIndex", [
            Column.mediumText("mediumText").index().change(),
          ])
        )
      expect DbError:
        rdb.alter(
          table("TypeIndex", [
            Column.mediumText("mediumText").unique().change(),
          ])
        )

    test("longText"):
      expect DbError:
        rdb.alter(
          table("TypeIndex", [
            Column.longText("longText").default("A").change(),
          ])
        )
      expect DbError:
        rdb.create(
          table("TypeIndex", [
            Column.longText("longText").index().change(),
          ])
        )
      expect DbError:
        rdb.create(
          table("TypeIndex", [
            Column.longText("longText").unique().change(),
          ])
        )

    test("binary"):
      expect DbError:
        rdb.alter(
          table("TypeIndex", [
            Column.binary("binary").default("A").change(),
          ])
        )
      expect DbError:
        rdb.create(
          table("TypeIndex", [
            Column.binary("binary").index().change(),
          ])
        )
      expect DbError:
        rdb.create(
          table("TypeIndex", [
            Column.binary("binary").unique().change(),
          ])
        )

    test("json"):
      expect DbError:
        rdb.alter(
          table("TypeIndex", [
            Column.json("json").default(%*{"key": "value"}).change(),
          ])
        )
      expect DbError:
        rdb.alter(
          table("TypeIndex", [
            Column.json("json").index().change(),
          ])
        )
      expect DbError:
        rdb.alter(
          table("TypeIndex", [
            Column.json("json").unique().change(),
          ])
        )


suite("MySQL alter table"):
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
        Column.text("text").add(),
        Column.mediumText("mediumText").add(),
        Column.longText("longText").add(),
        Column.date("date").index().default().add(),
        Column.datetime("datetime").index().default(),
        Column.time("time").index().default().add(),
        Column.timestamp("timestamp").index().default().add(),
        Column.timestamps().add(),
        Column.softDelete().add(),
        Column.binary("binary").add(),
        Column.boolean("boolean").index().default(true).add(),
        Column.enumField("enumField", ["A", "B", "C"]).index().default("A").add(),
        Column.json("json").add(),
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
        Column.text("text").add(),
        Column.mediumText("mediumText").add(),
        Column.longText("longText").add(),
        Column.date("date").unique().index().default().add(),
        Column.datetime("datetime").unique().index().default().add(),
        Column.time("time").unique().index().default().add(),
        Column.timestamp("timestamp").unique().index().default().add(),
        Column.timestamps().add(),
        Column.softDelete().add(),
        Column.binary("binary").add(),
        Column.boolean("boolean").unique().index().default(true).add(),
        Column.enumField("enumField", ["A", "B", "C"]).unique().index().default("A").add(),
        Column.json("json").add()
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
    except:
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
    except:
      check true


suite($rdb & " primary"):
  test("primary key"):
    rdb.create(
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
    )


clearTables(rdb).waitFor()
