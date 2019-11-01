allographer
===

A Nim query builder library inspired by [Laravel/PHP](https://readouble.com/laravel/6.0/en/queries.html) and [Orator/Python](https://orator-orm.com)

## Easy to access RDB
### Query Builder
```
import allographer/QueryBuilder

var result = RDB()
            .table("users")
            .select("id", "email", "name")
            .limit(5)
            .offset(10)
            .get()
echo result

>> SELECT id, email, name FROM users LIMIT 5 OFFSET 10
>> @[
    @["11", "user11@gmail.com", "user11"],
    @["12", "user12@gmail.com", "user12"],
    @["13", "user13@gmail.com", "user13"],
    @["14", "user14@gmail.com", "user14"],
    @["15", "user15@gmail.com", "user15"]
]
```

### Schema Builder
```
import allographer/SchemaBuilder

Schema().create([
  Model().create("auth", [
    Column().increments("id"),
    Column().string("name").nullable(),
    Column().timestamp("created_at").default()
  ])
])

>> CREATE TABLE auth (
    id INT NOT NULL PRIMARY KEY,
    name VARCHAR,
    created_at DATETIME DEFAULT (NOW())
)

Schema().create([
  Table().create("users", [
    Column().increments("id"),
    Column().string("name"),
    Column().foreign("auth_id").reference("id").on("auth").onDelete(SET_NULL)
  ])
])

>> CREATE TABLE users (
    id INT NOT NULL PRIMARY KEY,
    name VARCHAR NOT NULL,
    auth_id INT,
    FOREIGN KEY(auth_id) REFERENCES auth(id) ON DELETE SET NULL
) 
```

---

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

- driver: `sqlite` or `mysql` or `postgres`
- conn: `sqlite/file/path` or `host:port`
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
