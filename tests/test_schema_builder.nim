import unittest, json
import ../src/allographer/schema_builder


suite "Schema builder":
  test "test":
    schema([
      table("test", [
        Column().increments("increments"),
        Column().integer("integer").nullable().unique().default(1).unsigned(),
        Column().smallInteger("smallInteger").nullable().unique().default(1).unsigned(),
        Column().mediumInteger("mediumInteger").nullable().unique().default(1).unsigned(),
        Column().bigInteger("bigInteger").nullable().unique().default(1).unsigned(),

        Column().decimal("decimal", 5, 2).nullable().unique().default(1).unsigned(),
        Column().double("double", 5, 2).nullable().unique().default(1).unsigned(),
        Column().float("float").nullable().unique().default(1).unsigned(),

        Column().char("char", 100).nullable().unique().default(1).unsigned(),
        Column().string("string").nullable().unique().default(1).unsigned(),
        Column().text("text").nullable().unique().default(1).unsigned(),
        Column().mediumText("mediumText").nullable().unique().default(1).unsigned(),
        Column().longText("longText").nullable().unique().default(1).unsigned(),

        Column().date("date").nullable().unique().default().unsigned(),
        Column().datetime("datetime").nullable().unique().default().unsigned(),
        Column().time("time").nullable().unique().default().unsigned(),
        Column().timestamp("timestamp").nullable().unique().default().unsigned(),

        Column().binary("binary").nullable().unique().default().unsigned(),
        Column().boolean("boolean").nullable().unique().default().unsigned(),
        Column().enumField("enumField", ["a", "b"]).nullable().unique().default().unsigned(),
        Column().json("json").nullable().unique().default().unsigned(),
      ], reset=true)
    ])
