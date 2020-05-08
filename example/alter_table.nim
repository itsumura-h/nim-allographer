import ../src/allographer/schema_builder
# import ../src/allographer/query_builder

schema(
  table("test1", [
    Column().increments("id"),
    Column().string("change").nullable(),
    Column().string("drop").nullable(),
  ], reset=true)
)

# alter([
#   table("test1", [
#     change("name").string("user_name").default(""),
#   ])
# ])


alter([
  table("test1", [
    add().string("add").default(""),
    change("change").string("after_change").default(""),
    drop("drop"),
  ]),

#   # rename("test2", "test3")
])
