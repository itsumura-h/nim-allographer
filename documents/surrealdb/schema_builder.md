Example: Schema Builder for SurrealDB
===
[back](../../README.md)

## index
<!--ts-->
* [Example: Schema Builder for SurrealDB](#example-schema-builder-for-surrealdb)
   * [index](#index)
   * [About SurrealDB](#about-surrealdb)
   * [Create table](#create-table)
   * [Alter Table](#alter-table)
      * [add column](#add-column)
      * [drop column](#drop-column)
      * [drop table](#drop-table)

<!-- Created by https://github.com/ekalinin/github-markdown-toc -->
<!-- Added by: root, at: Mon Jul 17 07:46:33 UTC 2023 -->

<!--te-->

---

## About SurrealDB
[SurrealDB official docs](https://surrealdb.com/docs)  
[SurrealDB Github](https://github.com/surrealdb/surrealdb)

SurrealDB is a next-generation database built on Rust that can handle all type of data structures-relational, document, and graph-and can run in-memory, on a single node, or in a distributed environment.  
It's response is JSON and allographer return as `JsonNode`.

## Create table
You can create `SCHEMAFULL` table for SurrealDB.

[DEFINE TABLE](https://surrealdb.com/docs/surrealql/statements/define/table)  
[DEFINE FIELD](https://surrealdb.com/docs/surrealql/statements/define/field)

```nim
import allographer/connection
import allographer/schema_builder

let surreal = dbOpen(SurrealDb, "test", "test", "user", "pass", "htttp://surreal", 8000, 5, 30, false, false).waitFor()

surreal.create([
  table("auth", [
    Column.increments("index"),
    Column.uuid("uuid"),
    Column.string("name"),
    Column.timestamps()
  ]),
  table("user", [
    Column.increments("index"),
    Column.string("name"),
    Column.foreign("auth").reference("id").on("auth").onDelete(SET_NULL)
  ])
])
```

These query run.

```sql
DEFINE TABLE `auth` SCHEMAFULL;
INSERT INTO `_autoincrement_sequences` {table: "auth", column: "index", max_index: 0};
DEFINE EVENT `autoincrement_auth_index` ON TABLE `auth` WHEN $event = "CREATE" THEN {
  LET $val = (SELECT `max_index` FROM `_autoincrement_sequences` WHERE `table` = "auth" AND `column` = "index" LIMIT 1)[0].max_index + 1;
  UPDATE `auth` MERGE {index: $val} WHERE id = $after.id;
  UPDATE `_autoincrement_sequences` MERGE {max_index: $val} WHERE `table` = "auth" AND `column` = "index";
};
DEFINE FIELD `index` ON TABLE `auth` TYPE int;
DEFINE INDEX `auth_index_unique` ON TABLE `auth` COLUMNS `index` UNIQUE;
DEFINE FIELD `uuid` ON TABLE `auth` TYPE string VALUE $value OR rand::uuid() ASSERT $value != NONE;
DEFINE INDEX `auth_uuid_unique` ON TABLE `auth` COLUMNS `uuid` UNIQUE;
DEFINE FIELD `name` ON TABLE `auth` TYPE string ASSERT string::len($value) < 255 AND $value != NONE VALUE $value OR '';
DEFINE FIELD `created_at` ON TABLE `auth` TYPE datetime VALUE $value OR time::now();
DEFINE INDEX `auth_created_at_index` ON TABLE `auth` COLUMNS `created_at`;
DEFINE FIELD `updated_at` ON TABLE `auth` TYPE datetime VALUE time::now();
DEFINE INDEX `auth_updated_at_index` ON TABLE `auth` COLUMNS `updated_at`;

DEFINE TABLE `user` SCHEMAFULL;
INSERT INTO `_autoincrement_sequences` {table: "user", column: "index", max_index: 0};
DEFINE EVENT `autoincrement_user_index` ON TABLE `user` WHEN $event = "CREATE" THEN {
  LET $val = (SELECT `max_index` FROM `_autoincrement_sequences` WHERE `table` = "user" AND `column` = "index" LIMIT 1)[0].max_index + 1;
  UPDATE `user` MERGE {index: $val} WHERE id = $after.id;
  UPDATE `_autoincrement_sequences` MERGE {max_index: $val} WHERE `table` = "user" AND `column` = "index";
};
DEFINE FIELD `index` ON TABLE `user` TYPE int;
DEFINE INDEX `user_index_unique` ON TABLE `user` COLUMNS `index` UNIQUE;
DEFINE FIELD `name` ON TABLE `user` TYPE string ASSERT string::len($value) < 255 AND $value != NONE VALUE $value OR '';
DEFINE FIELD `auth` ON TABLE `user` TYPE record (`auth`) ASSERT $value != NONE;
```


## Alter Table
### add column
```nim
surreal.alter(
  table("auth", [
    Column.increments("index").add(),
    Column.string("name").add(),
  ]),
  table("user",[
    Column.string("email").unique().default("").add(),
    Column.foreign("auth").reference("id").on("auth").onDelete(SET_NULL).add()
  ])
)
```

```sql
INSERT INTO `_autoincrement_sequences` {table: "auth", column: "index", max_index: 0};
DEFINE EVENT `autoincrement_auth_index` ON TABLE `auth` WHEN $event = "CREATE" THEN {
  LET $val = (SELECT `max_index` FROM `_autoincrement_sequences` WHERE `table` = "auth" AND `column` = "index" LIMIT 1)[0].max_index + 1;
  UPDATE `auth` MERGE {index: $val} WHERE id = $after.id;
  UPDATE `_autoincrement_sequences` MERGE {max_index: $val} WHERE `table` = "auth" AND `column` = "index";
}
DEFINE FIELD `index` ON TABLE `auth` TYPE int
DEFINE INDEX `auth_index_unique` ON TABLE `auth` COLUMNS `index` UNIQUE
DEFINE FIELD `name` ON TABLE `auth` TYPE string ASSERT string::len($value) < 255 AND $value != NONE VALUE $value OR ''
DEFINE FIELD `email` ON TABLE `user` TYPE string ASSERT string::len($value) < 255 AND $value != NONE VALUE $value OR ''
DEFINE INDEX `user_email_unique` ON TABLE `user` COLUMNS `email` UNIQUE
DEFINE FIELD `auth` ON TABLE `user` TYPE record (`auth`) ASSERT $value != NONE
```

### drop column
```nim
surreal.alter(
  table("user",
    Column.dropColumn("name")
  )
)
```

```sql
REMOVE FIELD `name` ON TABLE `user`
```

### drop table
```nim
rdb.drop(
  table("user")
)
```

```sql
REMOVE TABLE `user`
```
