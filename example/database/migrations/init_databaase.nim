import ../../../src/allographer/schema_builder
import ../connection

proc initDatabaase*() =
  ## 0001
  rdb.create([
    table("user", [
      Column.uuid("id").index().comment("User ID"),
      Column.string("name").comment("User name"),
      Column.string("email").comment("User email address"),
      Column.string("password").comment("User password"),
      Column.integer("created_at").index().comment("Created at"),
      Column.integer("updated_at").index().comment("Updated at"),
    ], "User table"),
    table("post", [
      Column.uuid("id").index().comment("Post ID"),
      Column.string("title").comment("Post title"),
      Column.string("content").comment("Post content"),
      Column.strForeign("user_id").reference("id").onTable("user").comment("User ID"),
      Column.integer("created_at").index().comment("Created at"),
      Column.integer("updated_at").index().comment("Updated at"),
    ], "Post table"),
  ])
