allographer
===

[![nimble](https://raw.githubusercontent.com/yglukhov/nimble-tag/master/nimble.png)](https://github.com/yglukhov/nimble-tag)  
![Build Status](https://github.com/itsumura-h/nim-allographer/workflows/Build%20and%20test%20Nim/badge.svg)


An asynchronous query builder library inspired by [Laravel/PHP](https://readouble.com/laravel/6.0/en/queries.html) and [Orator/Python](https://orator-orm.com) for Nim.  
Supported Databases are [Sqlite3](https://www.sqlite.org/index.html), [PostgreSQL](https://www.postgresql.org/), [MySQL](https://www.mysql.com/), [MariaDB](https://mariadb.org/) and [SurrealDB](https://surrealdb.com/).

## Easy to access Rdb
### Query Builder
```nim
import asyncdispatch, json
import allographer/connection
import allographer/query_builder

let maxConnections = 95
let timeout = 30
let rdb = dbOpen(PostgreSql, "database", "user", "password" "localhost", 5432, maxConnections, timeout)
# also available
# let rdb = dbOpen(Sqlite3, "/path/to/db/sqlite3.db", maxConnections=maxConnections, timeout=timeout)
# let rdb = dbOpen(MySQL, "database", "user", "password" "localhost", 3306, maxConnections, timeout)
# let rdb = dbOpen(MariaDB, "database", "user", "password" "localhost", 3306, maxConnections, timeout)
# let surreal = dbOpen(SurrealDb, "test_ns" "test_db", "user", "password" "http://localhost", 8000, maxConnections, timeout)

proc main(){.async.} =
  let result = await rdb
                    .table("users")
                    .select("id", "email", "name")
                    .limit(5)
                    .offset(10)
                    .get()
  echo result

waitFor main()

>> SELECT id, email, name FROM users LIMIT 5 OFFSET 10
>> @[
  {"id":11,"email":"user11@gmail.com","name":"user11"},
  {"id":12,"email":"user12@gmail.com","name":"user12"},
  {"id":13,"email":"user13@gmail.com","name":"user13"},
  {"id":14,"email":"user14@gmail.com","name":"user14"},
  {"id":15,"email":"user15@gmail.com","name":"user15"}
]
```

### Schema Builder
```nim
import allographer/schema_builder


rdb.create([
  table("auth", [
    Column.increments("id"),
    Column.string("name").nullable(),
    Column.timestamp("created_at").default()
  ]),
  table("users", [
    Column.increments("id"),
    Column.string("name"),
    Column.foreign("auth_id").reference("id").on("auth").onDelete(SET_NULL)
  ])
])

>> CREATE TABLE auth (
    id INT NOT NULL PRIMARY KEY,
    name VARCHAR,
    created_at DATETIME DEFAULT (NOW())
)
>> CREATE TABLE users (
    id INT NOT NULL PRIMARY KEY,
    name VARCHAR NOT NULL,
    auth_id INT,
    FOREIGN KEY(auth_id) REFERENCES auth(id) ON DELETE SET NULL
)

rdb.alter(
  table("users", [
    Column.string("email").unique().default("").add(),
    Column.deleteColumn("name")
  ])
)

>> ALTER TABLE "users" ADD COLUMN `email` UNIQUE DEFAULT "" CHECK (length(`email`) <= 255)
>> ALTER TABLE "users" DROP `name`
```

## Index
<!--ts-->
* [allographer](#allographer)
   * [Easy to access Rdb](#easy-to-access-rdb)
      * [Query Builder](#query-builder)
      * [Schema Builder](#schema-builder)
   * [Index](#index)
   * [Install](#install)
   * [Configuation](#configuation)
   * [Createing connection](#createing-connection)
   * [Logging](#logging)
   * [Documents](#documents)
   * [Nim API Documents](#nim-api-documents)
      * [Query Builder for RDB](#query-builder-for-rdb)
      * [Schema Builder for RDB](#schema-builder-for-rdb)
      * [Query Builder for SurrealDB](#query-builder-for-surrealdb)
   * [Development](#development)
      * [Branch naming rule](#branch-naming-rule)

<!-- Created by https://github.com/ekalinin/github-markdown-toc -->
<!-- Added by: root, at: Mon Jul 17 06:29:56 UTC 2023 -->

<!--te-->
---

## Install
```sh
nimble install allographer
```

If you get `SIGSEGV: Illegal storage access. (Attempt to read from nil?)` when trying to use the database you likely have a problem with the library path. On OS X the default is to check for the `brew --prefix` of the chosen driver, if that doesn't work it will look in `/usr/lib` or an environment variable `DYLD_xxx_PATH` where `xxx` if your driver: `SQLITE`, `MARIADB`, `MYSQL` or `POSTGRES`.

## Configuation
Allographer loads emvironment variables of `DB_SQLITE`, `DB_POSTGRES`, `DB_MYSQL` `DB_MARIADB` and `DB_SURREAL` to define which process should be **compiled**.<br>
These environment variables have to be set at compile time, so they have to be written in `config.nims` not in `.env`.

config.nims
```nim
import os

putEnv("DB_SQLITE", $true)
putEnv("DB_POSTGRES", $true)
```
In this example, even if your runtime environment lacks `mysqlclient-dev`, execution will success. However if your runtime environment lacks `sqlite3`, execution will fail.

## Createing connection
Database connection should be definded as singleton variable.

database.nim
```nim
import allographer/connection

let rdb* = dbOpen(PostgreSql, "database", "user", "password" "localhost", 5432, maxConnections, timeout)

# you can create connection for multiple database at same time.
let sqliteRdb* = dbOpen(Sqlite3, "/path/to/db/sqlite3.db", maxConnections=maxConnections, timeout=timeout)
let mysqlRdb* = dbOpen(MySQL, "database", "user", "password" "localhost", 3306, maxConnections, timeout)
let mariaRdb* = dbOpen(MariaDB, "database", "user", "password" "localhost", 3306, maxConnections, timeout)
let surrealDb* = dbOpen(SurrealDb, "test_ns" "test_db", "user", "password" "http://localhost", 8000, maxConnections, timeout)
```

Then, call connection when you run query.

run_sql.nim
```nim
import asyncdispatch
import allographer/query_builder
from database import rdb

proc main(){.async.}=
  echo await rdb.table("users").get()

waitFor main()
```

## Logging
Please set args in `dbOpen()`
```nim
proc dbOpen*(driver:Driver, database:string="", user:string="", password:string="",
            host: string="", port=0, maxConnections=1, timeout=30,
            shouldDisplayLog=false, shouldOutputLogFile=false, logDir=""):Rdb
```
- shouldDisplayLog: Whether display logging in terminal console or not.
- shouldOutputLogFile: Whether output logging in log file or not.
- logDir: Define logging dir path.


## Documents
[Query Builder for RDB](./documents/rdb/query_builder.md)  
[Schema Builder for RDB](./documents/rdb/schema_builder.md)  
[Query Builder for SurrealDB](./documents/surrealdb/query_builder.md)  
[Schema Builder for SurrealDB](./documents/surrealdb/schema_builder.md)  

## Nim API Documents
[connection](https://itsumura-h.github.io/nim-allographer/connection.html)  

### Schema Builder for RDB
[usecases/create](https://itsumura-h.github.io/nim-allographer/schema_builder/usecases/create.html)  
[alterusecases/](https://itsumura-h.github.io/nim-allographer/schema_builder/usecases/alter.html)  
[usecases/drop](https://itsumura-h.github.io/nim-allographer/schema_builder/usecases/drop.html)  
[models/table](https://itsumura-h.github.io/nim-allographer/schema_builder/models/table.html)  
[models/column](https://itsumura-h.github.io/nim-allographer/schema_builder/models/column.html)  
[queries/query_interface](https://itsumura-h.github.io/nim-allographer/schema_builder/queries/query_interface.html)  

### Query Builder for RDB
[rdb_types](https://itsumura-h.github.io/nim-allographer/query_builder/rdb/rdb_types.html)  
[rdb_interface](https://itsumura-h.github.io/nim-allographer/query_builder/rdb/rdb_interface.html)  
[grammars](https://itsumura-h.github.io/nim-allographer/query_builder/rdb/query/grammar.html)

### Query Builder for SurrealDB
[surreal_types](https://itsumura-h.github.io/nim-allographer/query_builder/surreal/surreal_types.html)  
[surreal_interface](https://itsumura-h.github.io/nim-allographer/query_builder/surreal/surreal_interface.html)  
[grammars](https://itsumura-h.github.io/nim-allographer/query_builder/surreal/query/grammar.html)  

## Development
### Branch naming rule
Please create this branch name when you will create a new pull request.

| Branch | Description |
| ------ | ----------- |
| feature-*** | New feature branch |
| hotfix-*** | Bug fix branch |
| chore-*** | Chore work or maintenance |

This naming rule automatically labels the pull request.
