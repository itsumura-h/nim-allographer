import unittest, json
include ../src/allographer/schema_builder_pkg/column

suite "column options":
  test "default bool":
    var t = Column().default(true)
    check t.isDefault == true
    check t.defaultBool == true

  test "default int":
    var t = Column().default(3)
    check t.isDefault == true
    check t.defaultInt == 3

  test "default float":
    var t = Column().default(3.14)
    check t.isDefault == true
    check t.defaultFloat == 3.14

  test "default string":
    var t = Column().default("string")
    check t.isDefault == true
    check t.defaultString == "string"

  test "default null":
    var t = Column().default()
    check t.isDefault == true

  test "nullable":
    var t = Column().nullable()
    check t.isNullable == true

  test "unsigned":
    var t = Column().unsigned()
    check t.isUnsigned == true

suite "column type":
  test "increment":
    var t = Column().increments("id")
    check t.name == "id"
    check t.typ == rdbIncrements

  test "int":
    var t = Column().integer("int")
    check t.name == "int"
    check t.typ == rdbInteger

  test "small int":
    var t = Column().smallInteger("int")
    check t.name == "int"
    check t.typ == rdbSmallInteger

  test "medium int":
    var t = Column().mediumInteger("int")
    check t.name == "int"
    check t.typ == rdbMediumInteger

  test "big int":
    var t = Column().bigInteger("int")
    check t.name == "int"
    check t.typ == rdbBigInteger

  test "decimal":
    var t = Column().decimal("decimal", 5, 2)
    check t.name == "decimal"
    check t.typ == rdbDecimal
    check t.info == %*{"maximum":5 , "digit":2}

  test "double":
    var t = Column().double("double", 5, 2)
    check t.name == "double"
    check t.typ == rdbDouble
    check t.info == %*{"maximum":5 , "digit":2}

  test "float":
    var t = Column().float("float")
    check t.name == "float"
    check t.typ == rdbFloat

  test "char":
    var t = Column().char("char", 10)
    check t.name == "char"
    check t.typ == rdbChar
    check t.info["maxLength"].getInt == 10

  test "string":
    var t = Column().string("string", 100)
    check t.name == "string"
    check t.typ == rdbString
    check t.info["maxLength"].getInt == 100

  test "text":
    var t = Column().text("text")
    check t.name == "text"
    check t.typ == rdbText

  test "mediumText":
    var t = Column().mediumText("mediumText")
    check t.name == "mediumText"
    check t.typ == rdbMediumText

  test "longText":
    var t = Column().longText("longText")
    check t.name == "longText"
    check t.typ == rdbLongText