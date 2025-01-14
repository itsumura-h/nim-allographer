import std/json
import ../../../src/allographer/schema_builder
import ../connection

proc createAllTypeTable*() =
  ## 0002
  rdb.create([
    table("IntRelation", [
      Column.increments("id")
    ]),
    table("StrRelation", [
      Column.uuid("uuid")
    ]),
    table("Types", [
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
      # Column.time("time").index().default(),
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
  ])
