```
allograoher
  ├ connection.nim
  ├ types.nim
  ├ query_builder.nim
  ├ query_builder
  │   ├ rdb
  │   │   ├ rdb_types.nim
  │   │   ├ rdb_interface.nim
  │   │   ├ rdb_utils.nim
  │   │   ├ query
  │   │   │   ├ builder.nim
  │   │   │   ├ generator.nim
  │   │   │   ├ grammer.nim
  │   │   │   ├ exec.nim
  │   │   │   ├ transaction.nim
  │   │   │   └ seeder.nim
  │   │   └ databases
  │   │       ├ database_types.nim
  │   │       ├ sqlite
  │   │       │   ├ sqlite_rdb.nim
  │   │       │   ├ sqlite_lib.nim
  │   │       │   └ sqlite_impl.nim
  │   │       ├ mysql
  │   │       │   ├ mysql_rdb.nim
  │   │       │   ├ mysql_lib.nim
  │   │       │   └ mysql_impl.nim
  │   │       ├ mariadb
  │   │       │   ├ mariadb_rdb.nim
  │   │       │   ├ mariadb_lib.nim
  │   │       │   └ mariadb_impl.nim
  │   │       └ postgre
  │   │           ├ postgre_rdb.nim
  │   │           ├ postgre_lib.nim
  │   │           └ postgre_impl.nim
  │   └ surreal
  │       ├ surreal_types.nim
  │       ├ surreal_interface.nim
  │       ├ query
  │       │ ├ builder.nim
  │       │ ├ generator.nim
  │       │ ├ grammer.nim
  │       │ └ exec.nim
  │       └ databases
  │           ├ surreal_rdb.nim
  │           ├ surreal_lib.nim
  │           └ surreal_impl.nim
  │
  ├ schema_builder.nim
  └ schema_builder
      ├ queries
      │  ├ sqlite
      │  │  ├ impl.nim
      │  │  └ sqlite_query.nim
      │  ├ mysql
      │  │  ├ impl.nim
      │  │  └ mysql_query.nim
      │  └ postgre
      │      ├ impl.nim
      │      └ postgre_query.nim
      ├ schema.nim
      └ grammers.nim
```

```nim
let sqliteConn:SqliteRdb = dbOpen(Sqlite3, ":memory:")
let res = sqliteConn.from("table").where("id", "=", 1).get().await

proc from(self:SqliteRdb):QueryObject =
  return QueryObject(
    query:self.query,
    queryString:self.queryString,
  )

proc where(self:QueryObject, col:string, ):QueryObject

proc get(self:QueryObject):seq[Row] {.async.}
```
