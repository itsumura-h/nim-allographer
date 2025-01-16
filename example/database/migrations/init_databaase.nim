import ../../../src/allographer/schema_builder
import ../connection

proc init_databaase*() =
  ## 0001
  rdb.create([
    table("user", [
      Column.uuid("id").index().comment("ユーザーID"),
      Column.string("name").comment("ユーザー名"),
      Column.string("email").comment("ユーザーのメールアドレス"),
      Column.string("password").comment("ユーザーのパスワード"),
      Column.integer("created_at").index().comment("作成日時"),
      Column.integer("updated_at").index().comment("更新日時"),
    ], "ユーザーテーブル"),
    table("post", [
      Column.uuid("id").index().comment("投稿ID"),
      Column.string("title").comment("投稿タイトル"),
      Column.string("content").comment("投稿内容"),
      Column.strForeign("user_id").reference("id").onTable("user").comment("ユーザーID"),
      Column.integer("created_at").index().comment("作成日時"),
      Column.integer("updated_at").index().comment("更新日時"),
    ], "投稿テーブル"),
  ])
