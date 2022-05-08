discard """
  cmd: "nim c -d:reset -r $file"
"""

import unittest, asyncdispatch
import json, strformat, options
import ../src/allographer/schema_builder
import ../src/allographer/query_builder
import connections

for rdb in dbConnections:
  rdb.create(
    table("foreign_key_ref", [
      Column.increments("id"),
      Column.string("name")
    ]),
    table("table_alter", [
      Column.increments("id"),
      Column.string("changed_column").unique().default(""),
      Column.integer("changed_int").unique().default(0).unsigned(),
      Column.string("delete_column").nullable(),
    ]),
    table("table_rename", [
      Column.increments("id"),
    ]),
    table("table_drop", [
      Column.increments("id"),
    ])
  )

  try:
    rdb.alter(
      drop("table_rename_success")
    )
  except:
    discard

  var table_alter_data, table_rename_data, table_drop_data = newSeq[JsonNode](10)
  for i in 1..10:
    table_alter_data[i-1] = %*{
      "id": i,
      "changed_column": &"change{i}",
      "changed_int": i,
      "delete_column": &"delete{i}"
    }
    table_rename_data[i-1] = %*{
      "id": i
    }
    table_drop_data[i-1] = %*{
      "id": i
    }

  asyncBlock:
    rdb.table("table_alter").insert(table_alter_data).await
    rdb.table("table_rename").insert(table_rename_data).await
    rdb.table("table_drop").insert(table_drop_data).await


  block addColumnTest:
    asyncBlock:
      check rdb.table("table_alter").select("add_column").first.await.isSome == false

      rdb.alter(
        table("table_alter", [
          Column.string("add_column").default("")
        ])
      )

      rdb.table("table_alter").where("id", "=", 1).update(%*{"add_column": "test"}).await

      check rdb
        .table("table_alter")
        .select("add_column")
        .orderBy("id", Asc)
        .first
        .await
        .get["add_column"]
        .getStr == "test"

  block addForeignKeyTest:
    asyncBlock:
      rdb.alter(
        table("table_alter", [
          Column.foreign("add_foreign_column").reference("id").on("foreign_key_ref").onDelete(SET_NULL).add(),
        ])
      )
      check rdb.table("table_alter").select("add_foreign_column").first.await.isSome == true

      rdb.alter(
        table("table_alter", [
          Column.deleteColumn("add_foreign_column"),
        ])
      )
      check rdb.table("table_alter").select("add_foreign_column").first.await.isSome == false


  block changedColumnTest:
    asyncBlock:
      echo rdb
        .table("table_alter")
        .select("changed_column")
        .orderBy("id", Asc)
        .get()
        .await
      check rdb
        .table("table_alter")
        .select("changed_column")
        .orderBy("id", Asc)
        .first.await
        .get["changed_column"]
        .getStr == "change1"

      rdb.alter(
        table("table_alter", [
          Column.renameColumn("changed_column", "changed_column_success"),
          Column.renameColumn("changed_int", "changed_int_success"),
        ])
      )

      check rdb
        .table("table_alter")
        .select("changed_column_success")
        .orderBy("id", Asc)
        .first
        .await
        .get["changed_column_success"]
        .getStr == "change1"

      check rdb
        .table("table_alter")
        .select("changed_int_success")
        .orderBy("id", Asc)
        .first
        .await
        .get["changed_int_success"]
        .getInt == 1

  block deleteColumnTest:
    asyncBlock:
      check rdb
        .table("table_alter")
        .select("delete_column")
        .orderBy("id", Asc)
        .first.await
        .get["delete_column"].getStr == "delete1"

      rdb.alter(
        table("table_alter", [
          Column.deleteColumn("delete_column")
        ])
      )

      check rdb
        .table("table_alter")
        .select("delete_column")
        .orderBy("id", Asc)
        .first
        .await
        .isSome == false

  block renameTest:
    asyncBlock:
      check rdb
        .table("table_rename")
        .orderBy("id", Asc)
        .first
        .await
        .get["id"]
        .getInt == 1

      rdb.alter(rename("table_rename", "table_rename_success"))

      check rdb
        .table("table_rename_success")
        .orderBy("id", Asc)
        .first
        .await
        .get["id"]
        .getInt == 1

  block dropTableTest:
    asyncBlock:
      check rdb
        .table("table_drop")
        .orderBy("id", Asc)
        .first
        .await
        .get["id"]
        .getInt == 1

      rdb.alter(drop("table_drop"))

      check rdb
        .table("table_drop")
        .orderBy("id", Asc)
        .first
        .await
        .isSome == false
