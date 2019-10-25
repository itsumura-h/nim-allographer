allographer
===

A Nim query builder library inspired by [Laravel/PHP](https://readouble.com/laravel/6.0/en/queries.html) and [Orator/Python](https://orator-orm.com)

## Install
```
nimble install https://github.com/itsumura-h/nim-allographer
```

## Set up
First of all, add nim binary path
```
export PATH=$PATH:~/.nimble/bin
```
After install allographer, "dbtool" command is going to be available.  

### Create config file
```
cd /your/project/dir
dbtool makeConf
```
`/your/project/dir/config/database.ini` will be generated

### Edit confing file
By default, config file is set to use sqlite

```
[Connection]
driver: "sqlite"
conn: "/your/project/dir/db.sqlite3"
user: ""
password: ""
database: ""

[Log]
display: "true"
file: "true"
```

- driver: sqlite/mysql/postgres
- conn: sqlite file path / host:port
- user: login user name
- password: login password
- database: specify the database

From "conn" to "database", these are correspond to args of open proc of Nim std db package
```
let db = open(conn, user, password, database)
```

If you set "true" in "display" of "Log", SQL query will be display in terminal, otherwise nothing will be display.

### Load config file
```
dbtool loadConf
```
settings will be applied

## Examples
[Query Builder](./documents/QueryBuilder.md)  
[Schema Builder](./documents/SchemaBuilder.md)  


## Todo
- [x] Database migration
- [ ] Mapping with column and data then return JsonNode
- [ ] Aggregate methods (count, max, min, avg, and sum)
