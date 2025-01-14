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
      Column.integer("integer"),
      Column.smallInteger("smallInteger"),
      Column.mediumInteger("mediumInteger"),
      Column.bigInteger("bigInteger"),
      Column.decimal("decimal", 10, 3),
      Column.double("double", 10, 3),
      Column.float("float"),
      Column.uuid("uuid"),
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
      Column.foreign("int_relation_id").reference("id").onTable("IntRelation").onDelete(SET_NULL),
      Column.strForeign("str_relation_id").reference("uuid").onTable("StrRelation").onDelete(SET_NULL)
    ]),
  ])
