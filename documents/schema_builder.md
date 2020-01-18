Example: Schema Builder
===
[back](../README.md)

## Bacic useage
```nim
import allographer/schema_builder

schema([
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

## integer
|COMMAND|DESCRIPTION|
|---|---|
|`increments("id")`|Auto-incrementing UNSIGNED INTEGER (primary key) equivalent column.|
|`integer("votes")`|INTEGER equivalent column.|
|`smallInteger("votes")`|SMALLINT equivalent column|
|`mediumInteger("votes")`|MEDIUMINT equivalent column|
|`bigInteger("votes")`|UNSIGNED BIGINT equivalent column.|

## float
|COMMAND|DESCRIPTION|
|---|---|
|`decimal("amount", 8, 2)`|DECIMAL equivalent column with a precision (total digits) and scale (decimal digits).|
|`double("amount", 8, 2)`|DOUBLE equivalent column with a precision (total digits) and scale (decimal digits).|
|`float("float")`|FLOAT equivalent column with a implicit precision (total digits) and scale (decimal digits).|

## char
|COMMAND|DESCRIPTION|
|---|---|
|`char("name", 100)`|CHAR equivalent column with an optional length.|
|`string("name")`|VARCHAR equivalent column.|
|`string("name", 100)`|VARCHAR equivalent column with a optional length.|
|`text("description")`|TEXT equivalent column.|
|`mediumText("description")`|MEDIUMTEXT equivalent column.|
|`longText("description")`|LONGTEXT equivalent column.|

## date
|COMMAND|DESCRIPTION|
|---|---|
|`date("created_at")`|DATE equivalent column.|
|`datetime("created_at")`|DATETIME equivalent column.|
|`time("sunrise")`|TIME equivalent column.|
|`timestamp("added_on")`|TIMESTAMP equivalent column.|
|`timestamps()`|Adds nullable `created_at` and `updated_at` TIMESTAMP equivalent columns.|
|`softDelete()`|Adds a nullable `deleted_at` TIMESTAMP equivalent column for soft deletes.|

## others
|COMMAND|DESCRIPTION|
|---|---|
|`binary("data")`|BLOB equivalent column.|
|`boolean("confirmed")`|BOOLEAN equivalent column.|
|`enumField("level", ["easy", "hard"])`|ENUM equivalent column.|
|`json("options")`|JSON equivalent column.|

## options
|COMMAND|DESCRIPTION|
|---|---|
|`.nullable()`|Designate that the column allows NULL values|
|`.default(value)`|Declare a default value for a column|
|`.unsigned()`|Set INTEGER to UNSIGNED|

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