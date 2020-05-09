import ../src/allographer/schema_builder
# import ../src/allographer/query_builder

schema(
  table("table_alter", [
    Column().increments("id"),
    Column().string("changed_column").nullable(),
    Column().string("delete_column").nullable(),
  ], reset=true),
  table("table_rename", [
    Column().increments("id"),
  ]),
  table("table_drop", [
    Column().increments("id"),
  ])
)

alter([
  table("table_alter", [
    add().string("add_column").default(""),
    change("changed_column").string("changed_column_success").default(""),
    delete("delete_column"),
  ]),
  rename("table_rename", "table_rename_success"),
  drop("table_drop")
])
