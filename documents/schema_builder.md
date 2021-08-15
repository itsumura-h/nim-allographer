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
         * [delete column](#delete-column)
         * [rename table](#rename-table)
         * [drop table](#drop-table)
      * [integer](#integer)
      * [float](#float)
      * [char](#char)
      * [date](#date)
      * [others](#others)
      * [options](#options)
      * [Foreign Key Constraints](#foreign-key-constraints)

<!-- Added by: root, at: Sun Aug 15 03:35:25 UTC 2021 -->

<!--te-->
---

## Create table
```nim
import allographer/schema_builder
from database import rdb

rdb.schema([
  table("auth", [
    Column().increments("id"),
    Column().string("name"),
    Column().timestamps()
  ]),
  table("users", [
    Column().increments("id"),
    Column().string("name"),
    Column().foreign("auth_id").reference("id").on("auth").onDelete(SET_NULL)
  ], reset=true)
])
```
If you set `reset=true` in args of `Table().create`, `DROP TABLE` and `CREATE TABLE` will be run.

## Alter Table
### add column
```nim
rdb.alter(
  table("auth", [
    add().increments("id"),
    add().string("name"),
  ]),
  table("users",[
    add().string("email").unique().default(""),
    add().foreign("auth_id").reference("id").on("auth").onDelete(SET_NULL)
  ])
)
```
`>> ALTER TABLE "users" ADD COLUMN 'email' UNIQUE DEFAULT '' CHECK (length('email') <= 255)`


### change column
```nim
rdb.alter(
  table("users",
    change("name").char("new_name", 20).unique().default("")
  )
)
```
- Create new table with new column definition
- Rename table which you want to change column
- Copy table data from old table to new table
- Drop old table


### delete column
```nim
rdb.alter(
  table("users",
    delete().column("name")
    delete().foreign("auth_id")
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
rdb.alter(
  drop("users")
)
```
`>> DROP TABLE users`


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
Schema().foreign("user_id")
.reference("id")
.on("users")
.onDelete(SET_NULL)
```

arg of `onDelete` is enum
- RESTRICT
- CASCADE
- SET_NULL
- NO_ACTION
