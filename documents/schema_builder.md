Example: Schema Builder
===
[back](../README.md)

## Bacic useage
```
import allographer/schema_builder

Schema().create([
  Table().create("auth", [
    Column().increments("id"),
    Column().string("name"),
    Column().timestamps()
  ]),
  Table().create("users", [
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
|`Schema().increments("id")`|Auto-incrementing UNSIGNED INTEGER (primary key) equivalent column.|
|`Schema().integer("votes")`|INTEGER equivalent column.|
|`Schema().smallInteger("votes")`|SMALLINT equivalent column|
|`Schema().mediumInteger("votes")`|MEDIUMINT equivalent column|
|`Schema().bigInteger("votes")`|UNSIGNED BIGINT equivalent column.|

## float
|COMMAND|DESCRIPTION|
|---|---|
|`Schema().decimal("amount", 8, 2)`|DECIMAL equivalent column with a precision (total digits) and scale (decimal digits).|
|`Schema().double("amount", 8, 2)`|DOUBLE equivalent column with a precision (total digits) and scale (decimal digits).|
|`Schema().float("float")`|FLOAT equivalent column with a implicit precision (total digits) and scale (decimal digits).|

## char
|COMMAND|DESCRIPTION|
|---|---|
|`Schema().char("name", 100)`|CHAR equivalent column with an optional length.|
|`Schema().string("name")`|VARCHAR equivalent column.|
|`Schema().string("name", 100)`|VARCHAR equivalent column with a optional length.|
|`Schema().text("description")`|TEXT equivalent column.|
|`Schema().mediumText("description")`|MEDIUMTEXT equivalent column.|
|`Schema().longText("description")`|LONGTEXT equivalent column.|

## date
|COMMAND|DESCRIPTION|
|---|---|
|`Schema().date("created_at")`|DATE equivalent column.|
|`Schema().datetime("created_at")`|DATETIME equivalent column.|
|`Schema().time("sunrise")`|TIME equivalent column.|
|`Schema().timestamp("added_on")`|TIMESTAMP equivalent column.|
|`Schema().timestamps()`|Adds nullable `created_at` and `updated_at` TIMESTAMP equivalent columns.|
|`Schema().softDelete()`|Adds a nullable `deleted_at` TIMESTAMP equivalent column for soft deletes.|

## others
|COMMAND|DESCRIPTION|
|---|---|
|`Schema().binary("data")`|BLOB equivalent column.|
|`Schema().boolean("confirmed")`|BOOLEAN equivalent column.|
|`Schema().enumField("level", ["easy", "hard"])`|ENUM equivalent column.|
|`Schema().json("options")`|JSON equivalent column.|

## options
|COMMAND|DESCRIPTION|
|---|---|
|`.nullable()`|Designate that the column allows NULL values|
|`.default(value)`|Declare a default value for a column|
|`.unsigned()`|Set INTEGER to UNSIGNED|

## Foreign Key Constraints
For example, let's define a `user_id` column on the table that references the `id` column on a `users` table:
```
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