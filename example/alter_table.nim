import ../src/allographer/schema_builder
# import ../src/allographer/query_builder

schema(
  table("test1", [
    Column().increments("id"),
    Column().string("name").nullable()
  ], reset=true),
  table("test2", [
    Column().increments("id"),
    Column().string("name").nullable()
  ], reset=true),
)

# var sql = "ALTER TABLE users ADD COLUMN 'email' VARCHAR(255)"
# RDB().raw(sql).exec()

# sql = "ALTER TABLE users RENAME TO user_data"
# RDB().raw(sql).exec()

alter([
  table("test1", [
    add().string("email"),
    change("name").string("user_name"),
    drop("id"),
  ]),

  rename("test2", "test3")
])
