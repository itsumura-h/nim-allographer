allographer
===

[![nimble](https://raw.githubusercontent.com/yglukhov/nimble-tag/master/nimble.png)](https://github.com/yglukhov/nimble-tag)  
![Build Status](https://github.com/itsumura-h/nim-allographer/workflows/Build%20and%20test%20Nim/badge.svg)


An asynchronous query builder library inspired by [Laravel/PHP](https://readouble.com/laravel/6.0/en/queries.html) and [Orator/Python](https://orator-orm.com) for Nim

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


rdb.schema([
  table("auth", [
    Column().increments("id"),
    Column().string("name").nullable(),
    Column().timestamp("created_at").default()
  ]),
  table("users", [
    Column().increments("id"),
    Column().string("name"),
    Column().foreign("auth_id").reference("id").on("auth").onDelete(SET_NULL)
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
    add().string("email").unique().default(""),
    delete("name")
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
      * [Set up](#set-up)
      * [Configuation](#configuation)
      * [Createing connection](#createing-connection)
      * [Logging](#logging)
      * [Documents](#documents)
      * [Nim API Documents](#nim-api-documents)
         * [Query Builder](#query-builder-1)
         * [Schema Builder](#schema-builder-1)
      * [Development](#development)
         * [Branch naming rule](#branch-naming-rule)

<!-- Added by: root, at: Tue Feb 22 03:11:48 UTC 2022 -->

<!--te-->
---

## Install
```sh
nimble install allographer
```

## Set up
First of all, add nim binary path
```sh
export PATH=$PATH:~/.nimble/bin
```
After install allographer, "dbtool" command is going to be available.

If you get `SIGSEGV: Illegal storage access. (Attempt to read from nil?)` when trying to use the database you likely have a problem with the library path. On OS X the default is to check for the `brew --prefix` of the chosen driver, if that doesn't work it will look in `/usr/lib` or an environment variable `DYLD_xxx_PATH` where `xxx` if your driver: `SQLITE`, `MARIADB`, `MYSQL` or `POSTGRES`.

## Configuation
Allographer loads emvironment variables of `DB_SQLITE`, `DB_POSTGRES`, `DB_MYSQL` and `DB_MARIADB` to define which process should be **compiled**.<br>
These emvironment variables should be set at **compile time**, and create `config.nims` not `.env`

config.nims
```nim
import os

putEnv("DB_SQLITE", $true)
putEnv("DB_POSTGRES", $true)
```
In this example, even if your environment lacks `mysqlclient-dev`, compile will success. However if your environment lacks `sqlite3`, compile will fail.

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
[Query Builder](./documents/query_builder.md)  
[Schema Builder](./documents/schema_builder.md)  

## Nim API Documents
[connection](https://itsumura-h.github.io/nim-allographer/connection.html)  

### Query Builder
[base](https://itsumura-h.github.io/nim-allographer/query_builder/base.html)  
[grammars](https://itsumura-h.github.io/nim-allographer/query_builder/grammars.html)  
[exec](https://itsumura-h.github.io/nim-allographer/query_builder/exec.html)  

### Schema Builder
[schema](https://itsumura-h.github.io/nim-allographer/schema_builder/schema.html)  
[table](https://itsumura-h.github.io/nim-allographer/schema_builder/table.html)  
[column](https://itsumura-h.github.io/nim-allographer/schema_builder/column.html)  
[alter](https://itsumura-h.github.io/nim-allographer/schema_builder/alter.html)  


## Development
### Branch naming rule
Please create this branch name when you will create a new pull request.

| Branch | Description |
| ------ | ----------- |
| feature/*** | New feature branch |
| hotfix/*** | Bug fix branch |
| chore/*** | Chore work or maintenance |

This naming rule automatically labels the pull request.
