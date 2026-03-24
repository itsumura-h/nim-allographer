discard """
  cmd: "nim c -d:reset $file"
"""
# nim c -r -d:reset tests/sqlite/test_schema_length_check.nim

import std/unittest
import std/asyncdispatch
import std/json
import std/strformat
import std/strutils
import ../../src/allographer/schema_builder
import ../../src/allographer/query_builder
import ./connections
import ../clear_tables


let rdb = sqlite


proc tableSql(tableName:string): string =
  let rows = rdb.raw(&"SELECT sql FROM sqlite_master WHERE type = 'table' AND name = '{tableName}'").get().waitFor
  return rows[0]["sql"].getStr


suite("Sqlite length check constraint"):
  test("create table uses a column reference in CHECK"):
    let tableName = "length_check_create"

    rdb.create(
      table(tableName, [
        Column.increments("id"),
        Column.char("char", 4).default("ABCD"),
        Column.string("string", 4).nullable(),
        Column.uuid("uuid").nullable()
      ])
    )

    let sql = tableSql(tableName)
    check sql.contains("DEFAULT 'ABCD'")
    check sql.contains("CHECK (length(\"char\") <= 4)")
    check sql.contains("CHECK (length(\"string\") <= 4)")
    check sql.contains("CHECK (length(\"uuid\") <= 256)")

    expect DbError:
      rdb.table(tableName).insert(@[
        %*{
          "char": "ABCDE",
          "string": "ABCDE",
          "uuid": repeat("u", 300)
        }
      ]).waitFor


  test("add column keeps CHECK on a column reference"):
    let tableName = "length_check_add"

    rdb.create(
      table(tableName, [
        Column.increments("id")
      ])
    )

    rdb.alter(
      table(tableName, [
        Column.char("char", 4).nullable().add(),
        Column.string("string", 4).default("WXYZ").add(),
        Column.uuid("uuid").default("ZZZZ").add()
      ])
    )

    let sql = tableSql(tableName)
    check sql.contains("CHECK (length(\"char\") <= 4)")
    check sql.contains("CHECK (length(\"string\") <= 4)")
    check sql.contains("CHECK (length(\"uuid\") <= 256)")
    check sql.contains("DEFAULT 'WXYZ'")
    check sql.contains("DEFAULT 'ZZZZ'")

    expect DbError:
      rdb.table(tableName).insert(@[
        %*{
          "char": "ABCDE",
          "string": "ABCDE",
          "uuid": repeat("u", 300)
        }
      ]).waitFor


clearTables(rdb).waitFor
