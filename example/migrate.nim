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
    # add column
    Column.string("aaa").default("").add(),
    Column.foreign("bbb").reference("id").on("Auth").onDelete(SET_NULL).add(),
    # change column definition
    Column.string("aaa").nullable().change(),
    # change column name
    Column.renameColumn("aaa", "ccc"),
    # delete column
    Column.deleteColumn("ccc"),
    Column.deleteColumn("bbb"),
  ]),
  # change table name
  rename("Users", "members"),
  # drop table
  drop("members"),
])
