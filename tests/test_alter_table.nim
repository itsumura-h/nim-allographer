import unittest
import json, strformat, options
import ../src/allographer/schema_builder
import ../src/allographer/query_builder

schema(
  table("foreign_key_ref", [
    Column().increments("id"),
    Column().string("name")
  ], reset=true),
  table("table_alter", [
    Column().increments("id"),
    Column().string("changed_column").unique().default(""),
    Column().integer("changed_int").unique().default(0).unsigned(),
    Column().string("delete_column").nullable(),
  ], reset=true),
  table("table_rename", [
    Column().increments("id"),
  ], reset=true),
  table("table_drop", [
    Column().increments("id"),
  ], reset=true)
)

try:
  alter(drop("table_rename_success"))
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
rdb().table("table_alter").insert(table_alter_data)
rdb().table("table_rename").insert(table_rename_data)
rdb().table("table_drop").insert(table_drop_data)


suite "alter table":
  test "add_column":
    check rdb().table("table_alter").select("add_column").first.isSome == false

    alter(
      table("table_alter", [
        add().string("add_column").default("")
      ])
    )

    rdb().table("table_alter").where("id", "=", 1).update(%*{"add_column": "test"})

    check rdb()
      .table("table_alter")
      .select("add_column")
      .orderBy("id", Asc)
      .first.get["add_column"]
      .getStr == "test"

  test "add foreign key":
    alter(
      table("table_alter", [
        delete().column("add_foreign_column"),
        add().foreign("add_foreign_column").reference("id").on("foreign_key_ref").onDelete(SET_NULL),
      ])
    )
    check rdb().table("table_alter").select("add_foreign_column").first.isSome == true

    alter(
      table("table_alter", [
        delete().foreign("add_foreign_column"),
      ])
    )
    check rdb().table("table_alter").select("add_foreign_column").first.isSome == false


  test "changed_column":
    echo rdb()
      .table("table_alter")
      .select("changed_column")
      .orderBy("id", Asc)
      .get()
    check rdb()
      .table("table_alter")
      .select("changed_column")
      .orderBy("id", Asc)
      .first.get["changed_column"]
      .getStr == "change1"

    alter(
      table("table_alter", [
        change("changed_column").string("changed_column_success", 100).unique().default(""),
        change("changed_int").mediumInteger("changed_int_success").unique().default(0).unsigned(),
      ])
    )

    check rdb()
      .table("table_alter")
      .select("changed_column_success")
      .orderBy("id", Asc)
      .first.get["changed_column_success"]
      .getStr == "change1"

    check rdb()
      .table("table_alter")
      .select("changed_int_success")
      .orderBy("id", Asc)
      .first.get["changed_int_success"]
      .getInt == 1

  test "delete_column":
    check rdb()
      .table("table_alter")
      .select("delete_column")
      .orderBy("id", Asc)
      .first.get["delete_column"].getStr == "delete1"

    alter(
      table("table_alter", [
        delete().column("delete_column")
      ])
    )

    check rdb()
      .table("table_alter")
      .select("delete_column")
      .orderBy("id", Asc)
      .first.isSome == false

  test "rename":
    check rdb()
      .table("table_rename")
      .orderBy("id", Asc)
      .first.get["id"]
      .getInt == 1

    alter(rename("table_rename", "table_rename_success"))

    check rdb()
      .table("table_rename_success")
      .orderBy("id", Asc)
      .first.get["id"]
      .getInt == 1

  test "drop table":
    check rdb()
      .table("table_drop")
      .orderBy("id", Asc)
      .first.get["id"]
      .getInt == 1

    alter(drop("table_drop"))

    check rdb()
      .table("table_drop")
      .orderBy("id", Asc)
      .first.isSome == false
