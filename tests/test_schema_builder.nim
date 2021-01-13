import unittest, json
import ../src/allographer/schema_builder


suite "Schema builder":
  test "test":
    schema([
      table("sqlite", [
        Column().increments("increments"),
        Column().integer("integer").unique().default(1).unsigned().index(),
        Column().smallInteger("smallInteger").unique().default(1).unsigned().index(),
        Column().mediumInteger("mediumInteger").unique().default(1).unsigned().index(),
        Column().bigInteger("bigInteger").unique().default(1).unsigned().index(),

        Column().decimal("decimal", 5, 2).unique().default(1).unsigned().index(),
        Column().double("double", 5, 2).unique().default(1).unsigned().index(),
        Column().float("float").unique().default(1).unsigned().index(),

        Column().char("char", 100).unique().default("").unsigned().index(),
        Column().string("string").unique().default("").unsigned().index(),
        Column().text("text").default("").unique().default("").unsigned().index(),
        Column().mediumText("mediumText").unique().default("").unsigned().index(),
        Column().longText("longText").unique().default("").unsigned().index(),

        Column().date("date").unique().default().unsigned().index(),
        Column().datetime("datetime").unique().default().unsigned().index(),
        Column().time("time").unique().default().unsigned().index(),
        Column().timestamp("timestamp").unique().default().unsigned().index(),
        Column().timestamps(),
        Column().softDelete(),

        Column().binary("binary").unique().default().unsigned().index(),
        Column().boolean("boolean").unique().default().index(),
        Column().enumField("enumField", ["a", "b"]).unique().default().index(),
        Column().json("json").unique().default(%*{"key": "value"}).unsigned().index(),
      ], reset=true),

      # table("mysql", [
      #   Column().increments("increments"),
      #   Column().integer("integer").unique().default(1).unsigned(),
      #   Column().smallInteger("smallInteger").unique().default(1).unsigned(),
      #   Column().mediumInteger("mediumInteger").unique().default(1).unsigned(),
      #   Column().bigInteger("bigInteger").unique().default(1).unsigned(),

      #   Column().decimal("decimal", 5, 2).unique().default(1).unsigned(),
      #   Column().double("double", 5, 2).unique().default(1).unsigned(),
      #   Column().float("float").unique().default(1).unsigned(),

      #   Column().char("char", 100).unique().default(""),
      #   Column().string("string").unique().default(""),
      #   Column().text("text"),
      #   Column().mediumText("mediumText"),
      #   Column().longText("longText"),

      #   Column().date("date").unique().default(),
      #   Column().datetime("datetime").unique().default(),
      #   Column().time("time").unique().default(),
      #   Column().timestamp("timestamp").unique().default(),
      #   Column().timestamps(),
      #   Column().softDelete(),

      #   Column().binary("binary"),
      #   Column().boolean("boolean").unique().default(),
      #   Column().enumField("enumField", ["a", "b"]).unique().default("a"),
      #   Column().json("json"),
      # ], reset=true),

      # table("postgres", [
      #   Column().increments("increments"),
      #   Column().integer("integer").unique().default(1).unsigned(),
      #   Column().smallInteger("smallInteger").unique().default(1).unsigned(),
      #   Column().mediumInteger("mediumInteger").unique().default(1).unsigned(),
      #   Column().bigInteger("bigInteger").unique().default(1).unsigned(),

      #   Column().decimal("decimal", 5, 2).unique().default(1).unsigned(),
      #   Column().double("double", 5, 2).unique().default(1).unsigned(),
      #   Column().float("float").unique().default(1).unsigned(),

      #   Column().char("char", 100).unique().default(""),
      #   Column().string("string").unique().default(""),
      #   Column().text("text").unique().default(""),
      #   Column().mediumText("mediumText").unique().default(""),
      #   Column().longText("longText").unique().default(""),

      #   Column().date("date").unique().default(),
      #   Column().datetime("datetime").unique().default(),
      #   Column().time("time").unique().default(),
      #   Column().timestamp("timestamp").unique().default(),
      #   Column().timestamps(),
      #   Column().softDelete(),

      #   Column().binary("binary").unique().default(),
      #   Column().boolean("boolean").unique().default(),
      #   Column().enumField("enumField", ["a", "b"]).unique().default(),
      #   Column().json("json").default(%*{"key": "value"}),
      # ], reset=true)
    ])
