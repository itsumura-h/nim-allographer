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


rdb_interface
```nim
proc get*(self: Rdb):Future[seq[JsonNode]]
  # クエリ生成
  # ログ出力
  # getAllRowsを呼び出し
  # エラーハンドリング

proc getAllRows(self:Rdb | RawQueryRdb, queryString:string, args:seq[string]):Future[seq[JsonNode]]
  # クエリ実行
  # JSON化して返す
```

query/exec
```nim
proc query*(
  self: Connections,
  driver:Driver,
  query: string,
  args: seq[string] = @[],
  specifiedConnI=false,
  connI=0
):Future[(seq[Row], DbRows)]
  # コネクションを取得
  # 各DBに処理を振り分け
```

databases/sqlite/sqlite_impl
```nim
proc query*(db:PSqlite3, query:string, args:seq[string], timeout:int):Future[(seq[Row], DbRows)]
  # Sqlite固有の処理
```
