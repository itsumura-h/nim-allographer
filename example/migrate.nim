import strformat, json, oids, asyncdispatch
# import bcrypt
import ../src/allographer/query_builder
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
    # Column.string("Name").nullable(),
    # Column.string("email").nullable(),
    # Column.string("password").nullable(),
    # Column.string("address").nullable(),
    # Column.date("birth_date").nullable(),
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
    # # カラム削除
    Column.deleteColumn("ccc"),
  ]),
  # テーブル名変更
  rename("Users", "members"),
  # テーブル削除
  drop("members"),
])

# rdb.schema(
#   table("Auth",[
#     Column.increments("id"),
#     Column.uuid("uuid"),
#     Column.string("auth")
#   ]),
#   table("table", [
#     Column.increments("increments").index().nullable(),
#     Column.integer("integer").index().nullable().default(1),
#     Column.smallInteger("smallInteger").index().nullable().default(1),
#     Column.mediumInteger("mediumInteger").index().nullable().default(1),
#     Column.bigInteger("integer").index().nullable().default(1),
    
#     Column.decimal("decimal", 5, 3).index().nullable().default(1.1),
#     Column.double("double", 5, 3).index().nullable().default(1.1),
#     Column.float("float").index().nullable().default(1.1),

#     Column.uuid("uuid").index().nullable(),
#     Column.string("string").index().nullable().default("a"),
#     Column.char("char", 100).index().nullable().default("a"),
#     Column.text("text").index().nullable().default("a"),
#     Column.mediumText("mediumText").index().nullable().default("a"),
#     Column.longText("longText").index().nullable().default("a"),

#     Column.date("date").index().nullable().default("2000-01-01 01:01:01"),
#     Column.datetime("datetime").index().nullable().default("2000-01-01 01:01:01"),
#     Column.time("time").index().nullable().default("2000-01-01 01:01:01"),
#     Column.timestamp("timestamp").index().nullable().default("2000-01-01 01:01:01"),
#     Column.timestamps().index().nullable().default("2000-01-01 01:01:01"),
#     Column.softDelete().index().nullable().default("2000-01-01 01:01:01"),

#     Column.binary("binary").index().nullable().default("a"),
#     Column.boolean("boolean").index().nullable().default(false),
#     Column.enumField("enumField", ["aaa", "bbb"]).index().nullable().default("aaa"),
#     Column.json("json").index().nullable().default(%*{"key": "value"}),


#     Column.foreign("foreign").reference("id").on("Auth").onDelete(SET_NULL).nullable().default(1),
#     Column.strForeign("strForeign").reference("uuid").on("Auth").onDelete(SET_NULL).nullable().default("a"),
#   ])
# )

# # seeder
# # run query if Auth table is empty
# seeder rdb, "Auth":
#   waitFor rdb.table("Auth").insert(@[
#     %*{"auth": "admin"},
#     %*{"auth": "user"}
#   ])

# # run query if Users table is empty
# seeder rdb, "Users", "Name":
#   var insertData: seq[JsonNode]
#   for i in 1..100:
#     let salt = genSalt(10)
#     let password = hash(&"password{i}", salt)
#     let authId = if i mod 2 == 0: 1 else: 2
#     insertData.add(
#       %*{
#         "oid": $(genOid()),
#         "oid2": $(genOid()),
#         "Name": &"user{i}",
#         "email": &"user{i}@gmail.com",
#         "password": password,
#         "auth_id": authId
#       }
#     )
#   waitFor rdb.table("Users").insert(insertData)
