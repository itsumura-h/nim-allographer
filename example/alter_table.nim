import json, strformat
import ../src/allographer/schema_builder
import ../src/allographer/query_builder

schema(
  table("table_alter", [
    Column().increments("id"),
    Column().string("changed_column").nullable(),
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

var table_alter_data, table_rename_data, table_drop_data = newSeq[JsonNode](0)
for i in 1..10:
  table_alter_data.add(%*{
    "id": i,
    "changed_column": &"abc{i}",
    "delete_column": &"def{i}"
  })
  table_rename_data.add(%*{
    "id": i
  })
  table_drop_data.add(%*{
    "id": i
  })
RDB().table("table_alter").insert(table_alter_data)
RDB().table("table_rename").insert(table_rename_data)
RDB().table("table_drop").insert(table_drop_data)


alter([
  table("table_alter", [
    add().string("add_column").default(""),
    change("changed_column").string("changed_column_success").default(""),
    delete("delete_column"),
  ]),
  rename("table_rename", "table_rename_success"),
  drop("table_drop")
])
