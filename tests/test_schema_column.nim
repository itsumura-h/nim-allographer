discard """
  cmd: "nim c -d:reset -r $file"
"""

import std/unittest
import std/json
include ../src/allographer/schema_builder/grammars


suite("schema column"):
  test("default bool"):
    var t = Column.new().default(true)
    check t.isDefault == true
    check t.defaultBool == true

  test("default int"):
    var t = Column.new().default(3)
    check t.isDefault == true
    check t.defaultInt == 3

  test("defau;t float"):
    var t = Column.new().default(3.14)
    check t.isDefault == true
    check t.defaultFloat == 3.14

  test("default string"):
    var t = Column.new().default("string")
    check t.isDefault == true
    check t.defaultString == "string"

  test("default"):
    var t = Column.new().default()
    check t.isDefault == true

  test("nullable"):
    var t = Column.new().nullable()
    check t.isNullable == true

  test("unsigned"):
    var t = Column.new().unsigned()
    check t.isUnsigned == true

  test("unique"):
    var t = Column.new().unique()
    check t.isUnique == true

  test("index"):
    var t = Column.string("oid").index()
    check t.name == "oid"
    check t.isIndex == true

  test("increments"):
    var t = Column.increments("id")
    check t.name == "id"
    check t.typ == rdbIncrements

  test("integer"):
    var t = Column.integer("int")
    check t.name == "int"
    check t.typ == rdbInteger

  test("smallInteger"):
    var t = Column.smallInteger("int")
    check t.name == "int"
    check t.typ == rdbSmallInteger

  test("mediumInteger"):
    var t = Column.mediumInteger("int")
    check t.name == "int"
    check t.typ == rdbMediumInteger

  test("bigInteger"):
    var t = Column.bigInteger("int")
    check t.name == "int"
    check t.typ == rdbBigInteger

  test("decimal"):
    var t = Column.decimal("decimal", 5, 2)
    check t.name == "decimal"
    check t.typ == rdbDecimal
    check t.info == %*{"maximum":5 , "digit":2}

  test("double"):
    var t = Column.double("double", 5, 2)
    check t.name == "double"
    check t.typ == rdbDouble
    check t.info == %*{"maximum":5 , "digit":2}

  test("float"):
    var t = Column.float("float")
    check t.name == "float"
    check t.typ == rdbFloat

  test("char"):
    var t = Column.char("char", 10)
    check t.name == "char"
    check t.typ == rdbChar
    check t.info["maxLength"].getInt == 10

  test("string"):
    var t = Column.string("string", 100)
    check t.name == "string"
    check t.typ == rdbString
    check t.info["maxLength"].getInt == 100

  test("text"):
    var t = Column.text("text")
    check t.name == "text"
    check t.typ == rdbText

  test("mediumText"):
    var t = Column.mediumText("mediumText")
    check t.name == "mediumText"
    check t.typ == rdbMediumText

  test("longText"):
    var t = Column.longText("longText")
    check t.name == "longText"
    check t.typ == rdbLongText

  test("date"):
    var t = Column.date("date")
    check t.name == "date"
    check t.typ == rdbDate

  test("datetime"):
    var t = Column.datetime("datetime")
    check t.name == "datetime"
    check t.typ == rdbDatetime

  test("time"):
    var t = Column.time("time")
    check t.name == "time"
    check t.typ == rdbTime

  test("timestamp"):
    var t = Column.timestamp("timestamp")
    check t.name == "timestamp"
    check t.typ == rdbTimestamp

  test("timestamps"):
    var t = Column.timestamps()
    check t.typ == rdbTimestamps

  test("softDelete"):
    var t = Column.softDelete()
    check t.typ == rdbSoftDelete

  test("binary"):
    var t = Column.binary("binary")
    check t.name == "binary"
    check t.typ == rdbBinary

  test("boolean"):
    var t = Column.boolean("boolean")
    check t.name == "boolean"
    check t.typ == rdbBoolean

  test("enumField"):
    var t = Column.enumField("enumField", ["a", "b", "c"])
    check t.name == "enumField"
    check t.typ == rdbEnumField
    check t.info == %*{"options": ["a", "b", "c"]}

  test("json"):
    var t = Column.json("json")
    check t.name == "json"
    check t.typ == rdbJson

  test("foreign"):
    var t = Column.foreign("auth_id").reference("id").on("auth").onDelete(SET_NULL)
    check t.name == "auth_id"
    check t.typ == rdbForeign
    check t.info == %*{
      "column": "id",
      "table": "auth"
    }
    check t.foreignOnDelete == SET_NULL
