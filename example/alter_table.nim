import ../src/allographer/schema_builder
# import ../src/allographer/query_builder

schema(
  table("test1", [
    Column().increments("id"),
    Column().string("changed_column").nullable(),
    Column().string("delete_column").nullable(),
  ], reset=true),
  table("test2", [
    Column().increments("id"),
  ])
)

alter([
  table("test1", [
    add().string("add_column").default(""),
    change("changed_column").string("changed_column_success").default(""),
    delete("delete_column"),
  ]),
  rename("test2", "test3")
])
