Example: Schema Builder
===
[back](../README.md)

## index
<!--ts-->
* [Example: Schema Builder](#example-schema-builder)
   * [index](#index)
   * [Create table](#create-table)
   * [Alter Table](#alter-table)
      * [add column](#add-column)
      * [change column](#change-column)
      * [drop column](#drop-column)
      * [rename table](#rename-table)
      * [drop table](#drop-table)
   * [Migration history](#migration-history)
      * [seeder template](#seeder-template)
   * [integer](#integer)
   * [float](#float)
   * [char](#char)
   * [date](#date)
   * [others](#others)
   * [options](#options)
   * [Foreign Key Constraints](#foreign-key-constraints)

<!-- Created by https://github.com/ekalinin/github-markdown-toc -->
<!-- Added by: root, at: Mon Jul 17 06:30:07 UTC 2023 -->

<!--te-->
---

## Create table
```nim
import allographer/schema_builder
from ../database import rdb

rdb.create([
  table("auth", [
    Column.increments("id"),
    Column.uuid("uuid"),
    Column.string("name"),
    Column.timestamps()
  ]),
  table("users", [
    Column.increments("id"),
    Column.string("name"),
    Column.foreign("auth_id").reference("id").on("auth").onDelete(SET_NULL)
    Column.strForeign("uuid").reference("uuid").on("auth").onDelete(SET_NULL)
  ])
])
```

## Alter Table
### add column
```nim
rdb.alter(
  table("auth", [
    Column.increments("id").add(),
    Column.string("name").add(),
  ]),
  table("users",[
    Column.string("email").unique().default("").add(),
    Column.foreign("auth_id").reference("id").on("auth").onDelete(SET_NULL).add()
  ])
)
```
`>> ALTER TABLE "users" ADD COLUMN 'email' UNIQUE DEFAULT '' CHECK (length('email') <= 255)`


### change column
```nim
rdb.alter(
  table("users",
    Column.renameColumn("name", "new_name"),
    Column.char("name", 20).unique().default("").cange()
  )
)
```
- Create new table with new column definition
- Rename table which you want to change column
- Copy table data from old table to new table
- Drop old table


### drop column
```nim
rdb.alter(
  table("users",
    Column.dropColumn("name")
  )
)
```

### rename table
```nim
rdb.alter(
  rename("users", "new_users")
)
```
`>> ALTER TABLE users RENAME TO new_users`

### drop table
```nim
rdb.drop(
  table("users")
)
```
`>> DROP TABLE users`

## Migration history
allographer generate `_migrations` table in your database. It has migration history data which have hash key generated a query.


```nim
# migrate.nim
import json
import allographer/schema_builder
import allographer/query_builder

let rdb = dbopen(SQLite3, "/path/to/db.sqlite")

rdb.schema(
  table("auth", [
    Column.increments("id"),
    Column.string("name")
  ]),
  table("users", [
    Column.increments("id"),
    Column.string("name"),
    Column.foreign("auth_id").reference("id").in("auth").onDelete(SET_NULL)
  ])
)

seeder rdb, "auth":
  rdb.table("auth").insert(@[
    %*{"name": "admin"},
    %*{"name": "member"}
  ])
  .waitFor

seeder rdb, "users":
  var data: seq[JsonNode]
  for i in 1..10:
    data.add(%*{
      "name": &"user{i}",
      "auth_id": if i mod 2 == 0: 1 else: 2
    })
  rdb.table("users").insert(data).waitFor
```

```sh
# first time
nim c -r migrate
>> run query and generate `_migrations` table
# secound time
nim c -r migrate
>> nothing to do
# reset existsing table and run migration again
nim c -r migrate --reset
 or
nim c -d:reset -r migrate
>> drop table and create table
```

### seeder template
The `seeder` block allows the code in the block to work only when the table or specified column is empty.

```nim
template seeder*(rdb:Rdb, tableName:string, body:untyped):untyped

template seeder*(rdb:Rdb, tableName, column:string, body:untyped):untyped
```


## integer
|Command|Description|
|---|---|
|`increments("id")`|Auto-incrementing UNSIGNED INTEGER (primary key) equivalent column.|
|`integer("votes")`|INTEGER equivalent column.|
|`smallInteger("votes")`|SMALLINT equivalent column|
|`mediumInteger("votes")`|MEDIUMINT equivalent column|
|`bigInteger("votes")`|UNSIGNED BIGINT equivalent column.|

## float
|Command|Description|
|---|---|
|`decimal("amount", 8, 2)`|DECIMAL equivalent column with a precision (total digits) and scale (decimal digits).|
|`double("amount", 8, 2)`|DOUBLE equivalent column with a precision (total digits) and scale (decimal digits).|
|`float("float")`|FLOAT equivalent column with a implicit precision (total digits) and scale (decimal digits).|

## char
|Command|Description|
|---|---|
|`uuid("name")`|VARCHAR indexed and unique column.|
|`char("name", 100)`|CHAR equivalent column with an optional length.|
|`string("name")`|VARCHAR equivalent column.|
|`string("name", 100)`|VARCHAR equivalent column with a optional length.|
|`text("description")`|TEXT equivalent column.|
|`mediumText("description")`|MEDIUMTEXT equivalent column.|
|`longText("description")`|LONGTEXT equivalent column.|

## date
|Command|Description|
|---|---|
|`date("created_at")`|DATE equivalent column.|
|`datetime("created_at")`|DATETIME equivalent column.|
|`time("sunrise")`|TIME equivalent column.|
|`timestamp("added_on")`|TIMESTAMP equivalent column.|
|`timestamps()`|Adds nullable `created_at` and `updated_at` TIMESTAMP equivalent columns.|
|`softDelete()`|Adds a nullable `deleted_at` TIMESTAMP equivalent column for soft deletes.|

## others
|Command|Description|
|---|---|
|`binary("data")`|BLOB equivalent column.|
|`boolean("confirmed")`|BOOLEAN equivalent column.|
|`enumField("level", ["easy", "hard"])`|ENUM equivalent column.|
|`json("options")`|JSON equivalent column.|

## options
|Command|Description|
|---|---|
|`.nullable()`|Designate that the column allows NULL values|
|`.default(value)`|Declare a default value for a column|
|`.unsigned()`|Set INTEGER to UNSIGNED|
|`.unique()`|Adding an unique index|
|`.index()`|Adding an index|

## Foreign Key Constraints
For example, let's define a `user_id` column on the table that references the `id` column on a `users` table:
```nim
Column.foreign("user_id")
  .reference("id")
  .on("users")
  .onDelete(SET_NULL)

Column.strForeign("uuid")
  .reference("uuid")
  .on("users")
  .onDelete(SET_NULL)
```

arg of `onDelete` is enum
- RESTRICT
- CASCADE
- SET_NULL
- NO_ACTION
