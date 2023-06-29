discard """
  cmd: "nim c -r $file"
"""

import std/unittest
import std/asyncdispatch
import std/distros
import std/json
import std/oids
import std/options
import std/os
import std/strutils
import std/strformat
import std/times
import ../src/allographer/schema_builder
import ../src/allographer/query_builder
import ../src/allographer/connection
import ./connections


proc workflow(rdb:Rdb) =
  rdb.create(
    table("TypeIndex", [
      Column.integer("num"),
    ]),
    table("Drop", [
      Column.integer("num"),
    ]),
  )

  rdb.alter(
    table("TypeIndex", [
      Column.integer("num2").add(),
      Column.integer("num2").change(),
      Column.renameColumn("num2", "num3"),
      Column.deleteColumn("num3")
    ])
  )

  rdb.drop(
    table("Drop")
  )


for rdb in dbConnections:
  suite($rdb.driver & " reset schema builder"):
    rdb.raw("DROP TABLE IF EXISTS \"TypeIndex\"").exec().waitFor
    
    test("create table"):
      workflow(rdb)
      echo "======================="
      workflow(rdb)
