import unittest, json
import ../src/allographer/schema_builder


suite "Schema builder":
  test "test":
    schema([
      table("sqlite", [
        Column().increments("increments"),
        Column().integer("integer").unique().default(1).unsigned(),
        Column().smallInteger("smallInteger").unique().default(1).unsigned(),
        Column().mediumInteger("mediumInteger").unique().default(1).unsigned(),
        Column().bigInteger("bigInteger").unique().default(1).unsigned(),

        Column().decimal("decimal", 5, 2).unique().default(1).unsigned(),
        Column().double("double", 5, 2).unique().default(1).unsigned(),
        Column().float("float").unique().default(1).unsigned(),

        Column().char("char", 100).unique().default("").unsigned(),
        Column().string("string").unique().default("").unsigned(),
        Column().text("text").default("").unique().default("").unsigned(),
        Column().mediumText("mediumText").unique().default("").unsigned(),
        Column().longText("longText").unique().default("").unsigned(),

        Column().date("date").unique().default().unsigned(),
        Column().datetime("datetime").unique().default().unsigned(),
        Column().time("time").unique().default().unsigned(),
        Column().timestamp("timestamp").unique().default().unsigned(),

        Column().binary("binary").unique().default().unsigned(),
        Column().boolean("boolean").unique().default(),
        Column().enumField("enumField", ["a", "b"]).unique().default(),
        Column().json("json").unique().default().unsigned(),
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

      #   Column().char("char", 100).unique().default("").unsigned(),
      #   Column().string("string").unique().default("").unsigned(),
      #   Column().text("text").default("").unique().default("").unsigned(),
      #   Column().mediumText("mediumText").unique().default("").unsigned(),
      #   Column().longText("longText").unique().default("").unsigned(),

      #   Column().date("date").unique().default().unsigned(),
      #   Column().datetime("datetime").unique().default().unsigned(),
      #   Column().time("time").unique().default().unsigned(),
      #   Column().timestamp("timestamp").unique().default().unsigned(),

      #   Column().binary("binary").unique().default().unsigned(),
      #   Column().boolean("boolean").unique().default().unsigned(),
      #   Column().enumField("enumField", ["a", "b"]).unique().default().unsigned(),
      #   Column().json("json").unique().default().unsigned(),
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

      #   Column().char("char", 100).unique().default("").unsigned(),
      #   Column().string("string").unique().default("").unsigned(),
      #   Column().text("text").default("").unique().default("").unsigned(),
      #   Column().mediumText("mediumText").unique().default("").unsigned(),
      #   Column().longText("longText").unique().default("").unsigned(),

      #   Column().date("date").unique().default().unsigned(),
      #   Column().datetime("datetime").unique().default().unsigned(),
      #   Column().time("time").unique().default().unsigned(),
      #   Column().timestamp("timestamp").unique().default().unsigned(),

      #   Column().binary("binary").unique().default().unsigned(),
      #   Column().boolean("boolean").unique().default().unsigned(),
      #   Column().enumField("enumField", ["a", "b"]).unique().default().unsigned(),
      #   Column().json("json").unique().default().unsigned(),
      # ], reset=true)
    ])
