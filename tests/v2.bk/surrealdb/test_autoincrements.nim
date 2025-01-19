discard """
  cmd: "nim c -d:reset -r $file"
"""

import std/unittest
import std/asyncdispatch
import std/json
import std/options
import std/strformat
import ../../../src/allographer/query_builder
import ../../../src/allographer/schema_builder
import ../../connections
import ../../clear_tables


let rdb = surreal

suite("autoincrements"):
  test("sequence table is not exists"):
    rdb.raw("REMOVE TABLE _autoincrement_sequences").exec().waitFor()

    var info = rdb.raw("INFO FOR DB").info().waitFor()
    check not info[0]["result"]["tb"].contains("_autoincrement_sequences")

    rdb.create(
      table("user", [
        Column.increments("index"),
        Column.string("name")
      ])
    )

    info = rdb.raw("INFO FOR DB").info().waitFor()
    check info[0]["result"]["tb"].contains("_autoincrement_sequences")

    let id = rdb.table("user").insertId(%*{"name": "alice"}).waitFor()
    var user = rdb.table("user").find(id).waitFor().get()
    check user["name"].getStr == "alice"
    check user["index"].getInt == 1
    
    rdb.update(id, %*{"name": "updated"}).waitFor()
    
    user = rdb.table("user").find(id).waitFor().get()
    check user["name"].getStr == "updated"
    check user["index"].getInt == 1


  test("sequence table is exists"):
    var info = rdb.raw("INFO FOR DB").info().waitFor()
    check info[0]["result"]["tb"].contains("_autoincrement_sequences")

    rdb.create(
      table("user", [
        Column.increments("index"),
        Column.string("name")
      ])
    )

    let id = rdb.table("user").insertId(%*{"name": "alice"}).waitFor()
    var user = rdb.table("user").find(id).waitFor().get()
    check user["name"].getStr == "alice"
    check user["index"].getInt == 1
    
    rdb.update(id, %*{"name": "updated"}).waitFor()
    
    user = rdb.table("user").find(id).waitFor().get()
    check user["name"].getStr == "updated"
    check user["index"].getInt == 1


  test("cycle"):
    rdb.create(
      table("user", [
        Column.increments("index"),
        Column.string("name")
      ])
    )

    var users: seq[JsonNode]
    for i in 1..100:
      users.add(%*{"name": &"user{i}"})
    rdb.table("user").insert(users).waitFor()

    var user = rdb.table("user").where("index", "=", 1).first().waitFor().get()
    check user["index"].getInt == 1

    user = rdb.table("user").where("index", "=", 50).first().waitFor().get()
    check user["index"].getInt == 50

    user = rdb.table("user").where("index", "=", 100).first().waitFor().get()
    check user["index"].getInt == 100

    echo rdb.table("user").orderBy("index", Asc).limit(20).get().waitFor()

clearTables(rdb).waitFor()
