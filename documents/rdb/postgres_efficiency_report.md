# PostgreSQL driver 効率改善レポート

MariaDB driver に対して実施した効率改善と同様の観点で、PostgreSQL driver（`src/allographer/query_builder/libs/postgres/` および `models/postgres/`）を調査した結果をまとめる。

---

## P0: 重大（即時修正推奨）

### 1. `exec` / `insertId` が DML のたびに `information_schema.columns` を問い合わせている

**ファイル:** `models/postgres/postgres_exec.nim` 196-211行, 214-229行

```nim
proc exec(self:PostgresQuery, queryString:string) {.async.} =
  ...
  let table = self.query["table"].getStr
  let columnGetQuery = &"SELECT column_name, data_type FROM information_schema.columns WHERE table_name = '{table}'"
  let (columns, _) = postgres_impl.query(..., columnGetQuery, ...).await
  postgres_impl.exec(..., queryString, ..., columns, ...).await
```

**問題:**
- INSERT / UPDATE / DELETE のたびに追加で1回 SELECT が発生し、DML 性能が実質2倍遅くなる
- `'{table}'` の文字列補間は SQL インジェクションリスクがある（`insertId` にも同様の問題）

**改善案:**
MariaDB で実施済みの `columnTypeCache: Table[string, seq[seq[string]]]` を `Connections` に追加し、テーブルごとに初回のみ取得・キャッシュする。SQL はパラメータ化クエリに変更する。

---

## P1: 中程度

### 2. `waiters` が `seq[Future[void]]` で先頭削除が O(n)

**ファイル:** `models/postgres/postgres_types.nim` 20行, `models/postgres/postgres_exec.nim` 28-35行

```nim
# postgres_types.nim
waiters*: seq[Future[void]]

# postgres_exec.nim
proc wakeOnePoolWaiter(pools: Connections) =
  while pools.waiters.len > 0:
    let w = pools.waiters[0]
    pools.waiters.delete(0)   # ← O(n) のシフト操作
    ...
```

**問題:** `seq` の先頭削除は全要素シフトを伴う O(n) 操作。waiter が多い高負荷時に性能劣化する。`removePoolWaiter` も同じくリニアスキャン＋シフト。

**改善案:** `std/deques` の `Deque[Future[void]]` に変更。`popFirst()` が O(1)。MariaDB で実施済み。

### 3. `PgWaitState` が `ref object`（ヒープアロケーション）

**ファイル:** `libs/postgres/postgres_impl.nim` 14行

```nim
type
  PgWaitState = ref object
    cancelled: bool
```

**問題:** `waitPgReadable` / `waitPgWritable` が呼ばれるたびに `PgWaitState` のヒープアロケーションが発生する。

**改善案:** `object`（値型）に変更。async proc のクロージャ環境に格納されるため、値型でも正しく動作する。MariaDB で実施済み。

### 4. `waitPgReadable` と `waitPgWritable` がほぼ重複している

**ファイル:** `libs/postgres/postgres_impl.nim` 37-81行

```nim
proc waitPgReadable(db: PPGconn, timeoutMs: int): Future[bool] {.async.} =
  ...
  addRead(fd, readCb)      # ← 違いはここだけ
  ...

proc waitPgWritable(db: PPGconn, timeoutMs: int): Future[bool] {.async.} =
  ...
  addWrite(fd, writeCb)    # ← 違いはここだけ
  ...
```

**問題:** 2つの proc の差は `addRead` vs `addWrite` だけ。20行以上の完全な重複。

**改善案:** `waitPgIo(db, timeoutMs, forRead: bool)` のような統一 proc にまとめる。

### 5. `waitPgReadable` / `waitPgWritable` が `pqsocket` を二重に呼んでいる

**ファイル:** `libs/postgres/postgres_impl.nim` 37-58行

```nim
proc waitPgReadable(db: PPGconn, timeoutMs: int): Future[bool] {.async.} =
  ...
  ensurePgSocketRegistered(db)   # 内部で pqsocket(db) を呼ぶ
  let sock = pqsocket(db)        # ← 再度 pqsocket を呼んでいる
  if sock < 0:
    dbError(db)
  let fd = AsyncFD(cint(sock))
  ...
```

**問題:** `ensurePgSocketRegistered` 内で `pqsocket` を呼んで fd を得ているのに、その戻り値を使わず直後にもう一度 `pqsocket` を呼んでいる。FFI 呼び出しの無駄。

**改善案:** `ensurePgSocketRegistered` を `AsyncFD` を返す proc にする（MariaDB 版 `ensureMariadbSocketRegistered` と同じ設計）。

---

## P2: 軽微

### 6. `getTime().toUnix()` によるデッドライン計算（秒精度）

**ファイル:** `libs/postgres/postgres_impl.nim` 83-89行, 149-150行 他多数

```nim
proc pgRemainingMs(deadline: int64): int =
  let leftSec = deadline - getTime().toUnix()
  ...
  result = int(leftSec * 1000)

# deadline の生成（秒精度）
let calledAt = getTime().toUnix()
let deadline = calledAt + timeout.int64
```

**問題:**
- `getTime().toUnix()` は秒精度のため、ミリ秒単位のタイムアウト制御ができない
- NTP 補正によるクロック巻き戻りの影響を受ける
- `timeout = 1` のケースでは、0.9秒経過後に残り 0ms と判定される可能性がある

**改善案:** `std/monotimes` の `MonoTime` + `Duration` に統一する。MariaDB で実施済み。

### 7. `setColumnInfo` が行ごとに全カラム分の FFI 呼び出しを行っている

**ファイル:** `libs/postgres/postgres_lib.nim` 159-167行, `libs/postgres/postgres_impl.nim` 160-163行 他

```nim
# postgres_lib.nim
proc setColumnInfo*(res: PPGresult; dbRows: var DbRows; line, cols: int32) =
  var columns: DbColumns
  setLen(columns, cols)
  for col in 0'i32..cols-1:
    columns[col].name = $pqfname(res, col)          # 行に依存しない
    columns[col].typ = getColumnType(res, line, col) # NULL判定のみ行依存
    columns[col].tableName = $(pqftable(res, col))   # 行に依存しない
  dbRows.add(columns)

# postgres_impl.nim（query* 内）
for i in 0'i32 .. pqNtuples(pqresult) - 1:
  setRow(pqresult, row, i, cols)
  setColumnInfo(pqresult, dbRows, i, cols)   # ← 毎行で全カラム FFI 呼び出し
  rows.add(row)
```

**問題:** `pqfname`, `pqftable`, `pqftype` はカラムの OID・名前・テーブル名を返す関数で、行によって結果が変わらない。行に依存するのは `pqgetisnull(res, line, col)` による NULL 判定のみ。1000行×10カラムでは、カラム名・テーブル名だけで2万回の不要な FFI 呼び出し＋文字列アロケーションが発生する。

**改善案:** カラムの基本情報（name, tableName, OID）はループ外で1回だけ取得し、行ごとには NULL 判定のみ行う。

```nim
# 基本情報を1回だけ取得
var baseColumns: DbColumns
setLen(baseColumns, cols)
for col in 0'i32..cols-1:
  baseColumns[col].name = $pqfname(res, col)
  baseColumns[col].typ = getBaseColumnType(res, col)  # NULL判定なし
  baseColumns[col].tableName = $(pqftable(res, col))

# 行ごとにNULLだけ上書き
for i in 0'i32 .. pqNtuples(pqresult) - 1:
  setRow(pqresult, row, i, cols)
  var rowColumns = baseColumns
  for col in 0'i32..cols-1:
    if pqgetisnull(res, i, col) == 1:
      rowColumns[col].typ = DbType(kind: dbNull, name: "null")
  dbRows.add(rowColumns)
  rows.add(row)
```

### 8. `dbFormat` / `questionToDaller` の char-by-char 連結

**ファイル:** `libs/postgres/postgres_lib.nim` 203-216行, 219-229行

```nim
proc dbFormat*(formatstr: string, args: varargs[string]): string =
  result = ""
  ...
  for c in items(formatstr):
    if c == '?':
      add(result, dbQuote(args[a]))
      inc(a)
    else:
      add(result, c)           # ← 1文字ずつ add

proc questionToDaller*(s:string):string =
  var i = 1
  for c in s:
    if c == '?':
      result.add(&"${i}")
      i += 1
    else:
      result.add(c)            # ← 1文字ずつ add
```

**問題:** `?` が出現するまでの連続部分を1文字ずつ `add` しており、長いクエリ文字列で非効率。

**改善案:** `?` 位置間のサブ文字列を一括 `add` する。MariaDB の `dbFormat` で実施済みの手法。

### 9. `query*` / `rawQuery*` / `execGetValue*` のパラメータ送信パターンが重複

**ファイル:** `libs/postgres/postgres_impl.nim` 134-166行, 193-225行, 228-260行

```nim
# query*, execGetValue*, rawQuery* の冒頭がほぼ同一：
let status =
  if pgParams.nParams > 0:
    pqsendQueryParams(db, query.cstring, pgParams.nParams, nil, pgParams.values, ...)
  else:
    pqsendQueryParams(db, query.cstring, pgParams.nParams, nil, nil, nil, nil, 0)
defer:
  if pgParams.nParams > 0: pgParams.values.deallocCStringArray()
if status != 1: dbError(db)
```

**問題:** 4箇所にわたるクエリ送信ボイラープレート。保守コストが高い。

**改善案:** `pgSendQuery(db, pgParams)` のような共通 proc を抽出する。

### 10. `fromObjArray` の2つのオーバーロードが大部分重複

**ファイル:** `libs/postgres/postgres_lib.nim` 239-291行, 293-337行

**問題:** `columns` パラメータの有無のみが異なり、JSON→string 変換ロジックは同一。

**改善案:** 共通の内部 proc を抽出し、`columns` が空の場合はバイナリ判定をスキップする。

---

## P3: 微小

### 11. `dbQuote` の容量見積もりなし

**ファイル:** `libs/postgres/postgres_lib.nim` 182-201行

```nim
proc dbQuote(s: string): string =
  if s == "null":
    return "NULL"
  result = "'"
  ...
```

**問題:** `newStringOfCap` による事前容量確保がない。特殊文字が多い文字列で再アロケーションが発生する。

**改善案:** `result = newStringOfCap(s.len + 2)` を先頭に追加。

---

## 改善優先度まとめ

| 優先度 | # | 問題 | 影響 | 修正難度 |
|---|---|---|---|---|
| **P0** | 1 | `exec`/`insertId` が毎回 `information_schema` を問い合わせ + SQL インジェクション | DML ごとに追加1クエリ | 中（キャッシュ + パラメータ化） |
| **P1** | 2 | `waiters` の `seq.delete(0)` が O(n) | 高負荷時の性能劣化 | 低（`Deque` に変更） |
| **P1** | 3 | `PgWaitState` が `ref object` | 毎回のヒープアロケーション | 低（`object` に変更） |
| **P1** | 4 | `waitPgReadable`/`waitPgWritable` が重複 | 保守コスト | 低（統一） |
| **P1** | 5 | `pqsocket` 二重呼び出し | 不要な FFI 呼び出し | 低 |
| **P2** | 6 | `getTime().toUnix()` の秒精度デッドライン | タイムアウト精度 | 低（`MonoTime` 化） |
| **P2** | 7 | `setColumnInfo` が行ごとに全カラム FFI 呼び出し | 行数×カラム数の不要な FFI + アロケーション | 中（構造変更） |
| **P2** | 8 | `dbFormat`/`questionToDaller` の char-by-char | 長いクエリで微小な差 | 低 |
| **P2** | 9 | クエリ送信ボイラープレート重複 | 保守コスト | 低 |
| **P2** | 10 | `fromObjArray` の重複 | 保守コスト | 低 |
| **P3** | 11 | `dbQuote` の容量見積もりなし | 微小 | 低 |

---

## MariaDB との比較

| 項目 | MariaDB（修正済み） | PostgreSQL（現状） |
|---|---|---|
| カラム型キャッシュ | `columnTypeCache` 導入済み | 毎回 `information_schema` を問い合わせ |
| ブロッキング ping | 除去済み | `assert db.status == CONNECTION_OK`（FFI なし、問題小） |
| `setColumnInfo` 位置 | ループ外に移動済み | ループ内で毎行呼び出し |
| waiter データ構造 | `Deque` に変更済み | `seq`（先頭削除 O(n)） |
| 待機状態オブジェクト | 値型（`object`）に変更済み | `ref object`（ヒープ割当） |
| デッドライン | `MonoTime` に変更済み | `getTime().toUnix()`（秒精度） |
| `dbFormat` | セグメント一括 add | char-by-char |
| SQL インジェクション | プレースホルダ化済み | 文字列補間のまま |

**注意:** PostgreSQL の `assert db.status == CONNECTION_OK` は `pqStatus()` がローカルのフィールド読み取りであり、MariaDB の `mysql_ping()` のようなネットワークラウンドトリップは発生しない。そのため、PostgreSQL 側はこの assert の除去は不要。
