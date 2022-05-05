import json
import ../src/allographer/schema_builder
import connections


# migration
rdb.create([
  table("Auth",[
    Column.increments("id"),
    Column.string("auth")
  ]),
  table("Users",[
    Column.increments("id"),
    Column.uuid("uuid"),
    Column.string("oid").index().nullable(),
    Column.string("oid2").index().nullable(),
    Column.string("Name").nullable(),
    Column.date("birth_date").nullable(),
    Column.foreign("auth_id").reference("id").on("Auth").onDelete(SET_NULL).default(1)
  ]),
])

rdb.alter([
  table("Users", [
    # カラム追加
    Column.string("aaa").default("").add(),
    Column.foreign("bbb").reference("id").on("Auth").onDelete(SET_NULL).add(),
    # カラム定義変更
    Column.string("aaa").nullable().change(),
    # カラム名変更
    Column.renameColumn("aaa", "ccc"),
    # カラム削除
    Column.deleteColumn("ccc"),
    Column.deleteColumn("bbb"),
  ]),
  # テーブル名変更
  rename("Users", "members"),
  # テーブル削除
  drop("members"),
])
