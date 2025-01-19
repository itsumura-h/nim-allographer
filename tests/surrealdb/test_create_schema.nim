discard """
  cmd: "nim c -d:reset $file"
"""

import std/unittest
import std/asyncdispatch
import std/os
import std/strutils
import std/json
import ../../src/allographer/schema_builder
import ../connections
import ../clear_tables


let rdb = surreal
let schemaFilePath = getCurrentDir() / "schema.nim"

suite "Schema output after migration":
  setup:
    # schema.nim ファイルの削除
    if fileExists(schemaFilePath):
      removeFile(schemaFilePath)

    rdb.create(
      table("IntRelation", [
        Column.increments("id")
      ]),
      table("StrRelation", [
        Column.uuid("uuid")
      ]),
      table("TestSchemaOutput", [
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
        Column.timestamp("timestamp"),
        Column.timestamps(),
        Column.softDelete(),
        Column.binary("binary"),
        Column.boolean("boolean"),
        Column.enumField("enumField", ["A", "B", "C"]),
        Column.json("json"),
        Column.foreign("int_relation_id").reference("id").onTable("IntRelation").onDelete(SET_NULL),
        Column.strForeign("str_relation_id").reference("uuid").onTable("StrRelation").onDelete(SET_NULL)
      ])
    )


  test "should generate schema.nim file":
    # スキーマ生成
    rdb.createSchema().waitFor()
    
    # schema.nim ファイルの存在確認
    check fileExists(schemaFilePath)
    
    # ファイル内容の検証
    let schemaContent = readFile(schemaFilePath)
    echo "schemaContent: ", schemaContent
    check schemaContent.contains("type TestSchemaOutputTable* = object")
    check schemaContent.contains("integer*: int")
    check schemaContent.contains("smallInteger*: int")
    check schemaContent.contains("mediumInteger*: int")
    check schemaContent.contains("bigInteger*: int")
    check schemaContent.contains("decimal*: float")
    check schemaContent.contains("double*: float")
    check schemaContent.contains("float*: float")
    check schemaContent.contains("uuid*: string")
    check schemaContent.contains("char*: string")
    check schemaContent.contains("string*: string")
    check schemaContent.contains("text*: string")
    check schemaContent.contains("mediumText*: string")
    check schemaContent.contains("longText*: string")
    check schemaContent.contains("date*: string")
    check schemaContent.contains("datetime*: string")
    check schemaContent.contains("timestamp*: string")
    check schemaContent.contains("created_at*: string")
    check schemaContent.contains("updated_at*: string")
    check schemaContent.contains("deleted_at*: string")
    check schemaContent.contains("binary*: string")
    check schemaContent.contains("boolean*: bool")
    check schemaContent.contains("enumField*: string")
    check schemaContent.contains("json*: JsonNode")
    check schemaContent.contains("int_relation_id*: string")
    check schemaContent.contains("str_relation_id*: string")


clearTables(rdb).waitFor()
# schema.nim ファイルの削除
if fileExists(schemaFilePath):
  removeFile(schemaFilePath)
