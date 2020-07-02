import unittest
import json, strformat
import ../src/allographer/schema_builder
import ../src/allographer/query_builder

schema(
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
RDB().table("table_alter").insert(table_alter_data)
RDB().table("table_rename").insert(table_rename_data)
RDB().table("table_drop").insert(table_drop_data)


suite "alter table":
  test "add_column":
    check RDB().table("table_alter").select("add_column").first() == newJNull()

    alter(
      table("table_alter", [
        add().string("add_column").default("")
      ])
    )

    RDB().table("table_alter").where("id", "=", 1).update(%*{"add_column": "test"})

    check RDB()
      .table("table_alter")
      .select("add_column")
      .orderBy("id", Asc)
      .first()["add_column"]
      .getStr == "test"

  test "changed_column":
    check RDB()
      .table("table_alter")
      .select("changed_column")
      .orderBy("id", Asc)
      .first()["changed_column"]
      .getStr == "change1"

    alter(
      table("table_alter", [
        change("changed_column").string("changed_column_success", 100).unique().default(""),
        change("changed_int").mediumInteger("changed_int_success").unique().default(0).unsigned(),
      ])
    )

    check RDB()
      .table("table_alter")
      .select("changed_column_success")
      .orderBy("id", Asc)
      .first()["changed_column_success"]
      .getStr == "change1"

    check RDB()
      .table("table_alter")
      .select("changed_int_success")
      .orderBy("id", Asc)
      .first()["changed_int_success"]
      .getInt == 1

  test "delete_column":
    check RDB()
      .table("table_alter")
      .select("delete_column")
      .orderBy("id", Asc)
      .first()["delete_column"].getStr == "delete1"

    alter(
      table("table_alter", [
        delete("delete_column")
      ])
    )

    check RDB()
      .table("table_alter")
      .select("delete_column")
      .orderBy("id", Asc)
      .first() == newJNull()

  test "rename":
    check RDB()
      .table("table_rename")
      .orderBy("id", Asc)
      .first()["id"]
      .getInt == 1

    alter(rename("table_rename", "table_rename_success"))

    check RDB()
      .table("table_rename_success")
      .orderBy("id", Asc)
      .first()["id"]
      .getInt == 1

  test "drop table":
    check RDB()
      .table("table_drop")
      .orderBy("id", Asc)
      .first()["id"]
      .getInt == 1

    alter(drop("table_drop"))

    check RDB()
      .table("table_drop")
      .orderBy("id", Asc)
      .first() == newJNull()
