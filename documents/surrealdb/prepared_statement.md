Example: Prepared Statement for SurrealDB
===
> [!WARNING]
> SurrealDB の prepared statement は server-side prepare ではなく、client-side template reuse と `/sql` の multi-statement 実行で再現しています。

[back](../../README.md)

## index
<!--ts-->
* [Example: Prepared Statement for SurrealDB](#example-prepared-statement-for-surrealdb)
   * [index](#index)
   * [About](#about)
   * [Create Connection](#create-connection)
   * [prepare](#prepare)
   * [withConn](#withconn)
   * [Cache Control](#cache-control)
<!--te-->

---

## About
[SurrealDB official docs](https://surrealdb.com/docs)

Prepared statement の公開 API は他 driver に寄せていますが、SurrealDB では内部的に次の形へ展開します。

```sql
LET $a = "user:alice";
SELECT * FROM "user" WHERE "id" = $a;
```

`?` は `$a`, `$b`, ... に変換され、引数は `LET` で前置されます。これにより、1 リクエストで安全に再利用できるテンプレートとして扱えます。

## Create Connection

```nim
import std/asyncdispatch
import allographer/connection

let surreal = dbOpen(SurrealDB, "test", "test", "user", "pass", "http://surreal", 8000, 5, 30, false, false).await
```

## prepare

```nim
import std/asyncdispatch
import std/json
import allographer/query_builder

let stmt = surreal.prepare("""SELECT * FROM "user" WHERE "id" = ?""")
let rows = await stmt.get(@["user:alice"])
let row = await stmt.first(@["user:alice"])
await stmt.exec(@["user:alice"])
await stmt.close()
```

`close()` は logical close です。SurrealDB 側に物理 prepared handle はないため、キャッシュの整理は `flushStmt()` / `clearStmtCache()` で行います。

## withConn

```nim
await surreal.withConn(
  proc(ctx: SurrealPreparedContext): Future[void] {.async.} =
    discard await stmt.first(ctx, @["user:alice"])
    await stmt.exec(ctx, @["user:alice"])
)
```

`withConn()` は同じ connection index を使い回したいときの API です。将来の session 前提最適化や transaction helper とも相性がよい形にしてあります。

## Cache Control

```nim
await surreal.flushStmt(stmt)
await surreal.clearStmtCache()
```

`flushStmt(stmt)` はその prepared statement を閉じて、対応するテンプレートをキャッシュから外します。`clearStmtCache()` はキャッシュ全体を空にします。
