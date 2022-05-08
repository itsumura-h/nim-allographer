discard """
  cmd: "nim c -d:reset -r $file"
"""

import
  std/unittest,
  std/json
include ../src/allographer/schema_builder/grammers


block:
  var t = Column.new().default(true)
  check t.isDefault == true
  check t.defaultBool == true

block:
  var t = Column.new().default(3)
  check t.isDefault == true
  check t.defaultInt == 3

block:
  var t = Column.new().default(3.14)
  check t.isDefault == true
  check t.defaultFloat == 3.14

block:
  var t = Column.new().default("string")
  check t.isDefault == true
  check t.defaultString == "string"

block:
  var t = Column.new().default()
  check t.isDefault == true

block:
  var t = Column.new().nullable()
  check t.isNullable == true

block:
  var t = Column.new().unsigned()
  check t.isUnsigned == true

block:
  var t = Column.new().unique()
  check t.isUnique == true

block:
  var t = Column.string("oid").index()
  check t.name == "oid"
  check t.isIndex == true

block:
  var t = Column.increments("id")
  check t.name == "id"
  check t.typ == rdbIncrements

block:
  var t = Column.integer("int")
  check t.name == "int"
  check t.typ == rdbInteger

block:
  var t = Column.smallInteger("int")
  check t.name == "int"
  check t.typ == rdbSmallInteger

block:
  var t = Column.mediumInteger("int")
  check t.name == "int"
  check t.typ == rdbMediumInteger

block:
  var t = Column.bigInteger("int")
  check t.name == "int"
  check t.typ == rdbBigInteger

block:
  var t = Column.decimal("decimal", 5, 2)
  check t.name == "decimal"
  check t.typ == rdbDecimal
  check t.info == %*{"maximum":5 , "digit":2}

block:
  var t = Column.double("double", 5, 2)
  check t.name == "double"
  check t.typ == rdbDouble
  check t.info == %*{"maximum":5 , "digit":2}

block:
  var t = Column.float("float")
  check t.name == "float"
  check t.typ == rdbFloat

block:
  var t = Column.char("char", 10)
  check t.name == "char"
  check t.typ == rdbChar
  check t.info["maxLength"].getInt == 10

block:
  var t = Column.string("string", 100)
  check t.name == "string"
  check t.typ == rdbString
  check t.info["maxLength"].getInt == 100

block:
  var t = Column.text("text")
  check t.name == "text"
  check t.typ == rdbText

block:
  var t = Column.mediumText("mediumText")
  check t.name == "mediumText"
  check t.typ == rdbMediumText

block:
  var t = Column.longText("longText")
  check t.name == "longText"
  check t.typ == rdbLongText

block:
  var t = Column.date("date")
  check t.name == "date"
  check t.typ == rdbDate

block:
  var t = Column.datetime("datetime")
  check t.name == "datetime"
  check t.typ == rdbDatetime

block:
  var t = Column.time("time")
  check t.name == "time"
  check t.typ == rdbTime

block:
  var t = Column.timestamp("timestamp")
  check t.name == "timestamp"
  check t.typ == rdbTimestamp

block:
  var t = Column.timestamps()
  check t.typ == rdbTimestamps

block:
  var t = Column.softDelete()
  check t.typ == rdbSoftDelete

block:
  var t = Column.binary("binary")
  check t.name == "binary"
  check t.typ == rdbBinary

block:
  var t = Column.boolean("boolean")
  check t.name == "boolean"
  check t.typ == rdbBoolean

block:
  var t = Column.enumField("enumField", ["a", "b", "c"])
  check t.name == "enumField"
  check t.typ == rdbEnumField
  check t.info == %*{"options": ["a", "b", "c"]}

block:
  var t = Column.json("json")
  check t.name == "json"
  check t.typ == rdbJson

block:
  var t = Column.foreign("auth_id").reference("id").on("auth").onDelete(SET_NULL)
  check t.name == "auth_id"
  check t.typ == rdbForeign
  check t.info == %*{
    "column": "id",
    "table": "auth"
  }
  check t.foreignOnDelete == SET_NULL
