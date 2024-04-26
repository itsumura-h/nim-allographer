import ../../src/allographer/schema_builder
import ./connection

rdb.create(
  table("user", [
    Column.increments("id"),
    Column.string("name"),
    Column.string("email").unique(),
    Column.timestamps()
  ]),
  table("article", [
    Column.string("id").unique(),
    Column.string("title"),
    Column.text("content").nullable(),
    Column.timestamps(),
    Column.foreign("user_id").reference("id").onTable("user").onDelete(CASCADE),
  ]),
  table("tag", [
    Column.string("id").unique(),
    Column.string("name")
  ]),
  table("tag_article_map", [
    Column.strForeign("tag_id").reference("id").onTable("tag").onDelete(CASCADE),
    Column.strForeign("article_id").reference("id").onTable("article").onDelete(CASCADE)
  ])
)
