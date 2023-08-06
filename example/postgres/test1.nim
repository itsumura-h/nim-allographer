import std/asyncdispatch
import std/httpclient
import std/streams
import std/json
import std/db_postgres
import ../../src/allographer/connection
import ../../src/allographer/query_builder
import ../../src/allographer/schema_builder


proc main() {.async.} =
  let client = newAsyncHttpClient()
  let response = client.getContent("https://nim-lang.org/assets/img/twitter_banner.png").await
  let imageStream = newStringStream(response)
  let binaryImage = imageStream.readAll()

  let rdb = dbOpen(PostgreSQL, "database", "user", "pass", "postgres", 5432, shouldDisplayLog=true)
  await rdb.raw("DROP TABLE IF EXISTS \"test\"").exec()
  await rdb.raw("""
    CREATE TABLE "test" (
      "id" BIGSERIAL NOT NULL PRIMARY KEY,
      "bool" BOOLEAN,
      "int" INTEGER,
      "float" NUMERIC,
      "str" VARCHAR(256),
      "json" JSONB,
      "null" VARCHAR(256),
      "blob" BYTEA
    )
  """).exec()
  # rdb.create(
  #   table("test", [
  #     Column.increments("id"),
  #     Column.boolean("bool"),
  #     Column.integer("int"),
  #     Column.float("float"),
  #     Column.string("str"),
  #     Column.json("json"),
  #     Column.string("null").nullable(),
  #     Column.binary("blob"),
  #   ])
  # )

  let id = await rdb.table("test").insertId(%*{
    "blob": binaryImage,
    "bool": true,
    "int": 1,
    "float": 1.1,
    "str": "alice",
    "json": {"name":"alice", "email":"alice@example.com"},
    "null": nil
  })
  # echo rdb.table("test").get().await
  echo rdb.select("bool", "int", "float", "str", "json", "null").table("test").get().await

  await rdb.table("test").where("id", "=", id).update(%*{
    "blob": binaryImage,
    "bool": false,
    "int": 2,
    "float": 2.1,
    "json": {"name":"bob", "email":"bob@example.com"},
    "str": "bob",
  })
  echo rdb.select("bool", "int", "float", "str", "json", "null").table("test").get().await

  await rdb.raw(
    """
      UPDATE "test"
      SET
        "bool" = $1,
        "int" = $2,
        "float" = $3,
        "json" = $4,
        "str" = $5,
        "null" = $6
      WHERE "id" = $7
    """,
    %*[true, 3, 3.3, {"name":"charlie", "email":"charlie@example.com"}, "charlie", nil, 1]
  ).exec()
  echo rdb.raw("SELECT bool, int, float, json, str, \"null\" FROM \"test\"").get().await


main().waitFor()
