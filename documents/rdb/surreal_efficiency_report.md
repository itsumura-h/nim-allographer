# Surreal driver 効率改善レポート
> [!WARNING]
> SurrealDB support is planned for v3. The current implementation and proposed improvements are for reference only and will be addressed in v3.

`src/allographer/query_builder/libs/surreal/` と、その呼び出し元である `models/surreal/` を調査し、`documents/rdb/postgres_efficiency_report.md` と `320-allographerpostgresql-非同期待機改善-設計書.mdc` と同じ観点で、処理効率と待機制御の改善余地を整理した。

MariaDB / PostgreSQL 側で既に改善済みのポイントと比べると、Surreal 側は以下の 2 点が特に目立つ。

- 接続プール待機はすでに `Deque` + `MonoTime` ベースで改善済み
- 一方で HTTP リクエスト自体の timeout 制御と、初期化時の重複 round-trip は未整理

---

## P0: 重大

### 1. `timeout` 引数が HTTP リクエスト経路で使われていない

**ファイル:** `src/allographer/query_builder/libs/surreal/surreal_impl.nim` 47-112行

```nim
proc query*(db:SurrealConn, query: string, args: JsonNode, timeout:int):Future[JsonNode] {.async.} =
  let query = dbFormat(query, args)
  let resp = db.client.post(&"{db.host}:{db.port}/sql", query).await
  let body = resp.body().await.parseJson()
```

**問題:**
- `query` / `exec` / `info` の全経路で `timeout` が未使用
- 遅い HTTP 応答やハングした接続があると、その接続スロットを無期限に占有する
- `getFreeConn` 側は `MonoTime` で待機期限を持っていても、実リクエストが返らない限りコネクションは返却されず、スループットが崩れる
- PostgreSQL 設計書で整理した「待機制御を driver 内で完結させる」という方針と比べると、Surreal だけ実処理 timeout が抜けている

**改善案:**
- `post()` と `body()` を `withTimeout` で包み、`MonoTime` ベースの deadline へ統一する
- もしくは `AsyncHttpClient` 側の timeout 設定を `dbOpen` で明示し、driver 引数 `timeout` と同期させる
- エラー整形も共通化し、timeout 時は `DbError` へ寄せる

---

## P1: 中程度

### 2. `dbOpen` が接続数ぶん `/status` と `DEFINE NAMESPACE / DATABASE` を逐次実行している

**ファイル:** `src/allographer/query_builder/models/surreal/surreal_open.nim` 17-35行

```nim
for i in 0..<maxConnections:
  let client = newAsyncHttpClient()
  ...
  var resp = client.get(url).await
  ...
  resp = client.post(url, &"DEFINE NAMESPACE `{namespace}`; USE NS `{namespace}`; DEFINE DATABASE `{database}`").await
```

**問題:**
- 初期化コストが `maxConnections` に比例して直線的に増える
- 各接続ごとに `/status` と `DEFINE ...` を逐次実行しており、プール 10 本なら最低 20 回の HTTP round-trip が発生する
- `DEFINE NAMESPACE` / `DEFINE DATABASE` はプール内の全接続で毎回やる必要が薄く、重複コストになりやすい
- ループが直列なので、起動時間が RTT の影響を強く受ける

**改善案:**
- namespace/database の bootstrap は 1 接続だけで先に済ませ、残りは接続確認だけにする
- もしくは初期化を 1 本目の成功後に `allFutures` 系で並列化する
- あわせて `Authorization` の Base64 生成や URL 生成もループ外へ寄せる

### 3. `dbFormat(queryString, args: JsonNode)` が中間文字列を多量に生成する

**ファイル:** `src/allographer/query_builder/libs/surreal/surreal_lib.nim` 77-118行

```nim
var strArgs: seq[string]
...
strArgs.add(&"LET ${numToAlphabet(i)} = {$arg.getInt}; ")
...
result = strArgs.join() & queryPart
```

**問題:**
- 各引数ごとに `&` で新しい文字列を作る
- `strArgs` に積んだ後で `join()`、最後に `& queryPart` でもう一度連結する
- プレースホルダ数が多い bulk insert / update 系ほどアロケーションが増える
- MariaDB / PostgreSQL の `dbFormat` 改善と違い、Surreal の `JsonNode` 経路はまだ単一パス化されていない

**改善案:**
- `newStringOfCap` で見積もり確保し、`LET $a = ...; ` を `result` へ直接 `add` する
- `strArgs: seq[string]` と `join()` を廃止し、最後に `queryPart` を `add` する
- placeholder 名は毎回 `numToAlphabet` で再計算せず、ローカルキャッシュか直接 append する

### 4. `query` / `exec` / `info` の HTTP 実行ロジックが 6 箇所に重複している

**ファイル:** `src/allographer/query_builder/libs/surreal/surreal_impl.nim` 47-112行

```nim
let query = dbFormat(query, args)
let resp = db.client.post(&"{db.host}:{db.port}/sql", query).await
let body = resp.body().await.parseJson()
```

**問題:**
- `seq[string]` / `JsonNode` の 2 系統で `query`, `exec`, `info` がほぼ同一実装
- timeout 対応、HTTP status 判定、JSON parse、Surreal エラー整形を入れたいときに 6 箇所修正になる
- 毎回 `&"{db.host}:{db.port}/sql"` を再生成しており、ホットパスに細かな再アロケーションが残る

**改善案:**
- `runSql(db, sql: string): Future[JsonNode]` のような共通 proc を切り出す
- `dbFormat` だけ呼び出し側オーバーロードで吸収し、HTTP 送信・JSON parse・エラー判定は 1 箇所へ寄せる
- `SurrealConn` に `sqlUrl` を保持し、ホットパスの `strformat` をなくす

---

## P2: 軽微

### 5. `numToAlphabet` が placeholder ごとに前置連結と `toLower()` を行う

**ファイル:** `src/allographer/query_builder/libs/surreal/surreal_lib.nim` 44-55行

```nim
result = ""
while n > 0:
  ...
  result = chr(int('A') + remainder) & result
...
return result.toLower()
```

**問題:**
- `& result` による前置連結で、文字数に応じた再アロケーションが発生する
- 最後に `toLower()` でもう 1 回文字列を作る
- 1 回のコストは小さいが、`dbFormat(JsonNode)` と `questionToDaller()` の両方から頻繁に呼ばれる

**改善案:**
- 小さなバッファへ末尾追加して最後に reverse する
- もしくは最初から `'a'` 基準で生成して `toLower()` をなくす

### 6. `questionToDaller()` が `numToAlphabet()` と組み合わさって placeholder 数ぶん文字列生成を行う

**ファイル:** `src/allographer/query_builder/libs/surreal/surreal_lib.nim` 58-74行

```nim
if s[j] == '?':
  ...
  result.add('$')
  result.add(numToAlphabet(i))
```

**問題:**
- 文字列本体はセグメント単位で `add` できており悪くないが、placeholder 名生成が都度アロケーションになる
- `find()` 経路では `surreal_exec.nim` 366-369行で毎回 `questionToDaller` を通る

**改善案:**
- `numToAlphabet` 改善とセットで最適化する
- placeholder 数が少ないケースでは効果は小さいため、P1 の `dbFormat(JsonNode)` ほど優先度は高くない

### 7. `getAllRows()` が `JsonNode` 配列を `seq[JsonNode]` へ変換するため、結果件数ぶん追加走査が入る

**ファイル:** `src/allographer/query_builder/models/surreal/surreal_exec.nim` 121-138行, 184-201行

```nim
let rows = surreal_impl.query(...).await
...
return rows.toSeq
```

**問題:**
- `surreal_impl.query()` はすでに `JsonNode` の配列を返している
- `get()` / `insertId(seq)` のたびに `toSeq()` でもう一度全件を走査する
- 大量行取得では余分なイテレーションと `seq` 生成が発生する

**改善案:**
- 内部表現を `JsonNode` で統一して必要箇所だけ `seq` 化する
- あるいは `surreal_impl.query()` 側で最終的に必要な `seq[JsonNode]` を 1 回だけ組み立てる

---

## すでに良い点

### 1. プール待機は `Deque` + 通知ベースで、PostgreSQL 改善後と同じ方向にそろっている

**ファイル:** `src/allographer/query_builder/models/surreal/surreal_exec.nim` 24-75行

- `waiters` は `Deque[Future[void]]`
- `wakeOnePoolWaiter()` は `popFirst()` で O(1)
- `sleepAsync(10)` ポーリングは使っていない

### 2. プール待機の deadline は `MonoTime` ベース

**ファイル:** `src/allographer/query_builder/models/surreal/surreal_exec.nim` 40-69行

- PostgreSQL 改善設計書で問題視していた wall clock 依存は入っていない
- ただし「接続取得待ち」だけで、「HTTP 実行待ち」にはまだ広がっていない

---

## 改善優先度まとめ

| 優先度 | # | 問題 | 影響 | 修正難度 |
|---|---|---|---|---|
| **P0** | 1 | HTTP リクエストで `timeout` 未使用 | ハング時に接続が返却されず、プール全体が詰まる | 中 |
| **P1** | 2 | `dbOpen` が接続数ぶん逐次 bootstrap | 起動時間が `maxConnections` に比例 | 低〜中 |
| **P1** | 3 | `dbFormat(JsonNode)` の中間文字列多発 | bulk 系で CPU / アロケーション増 | 中 |
| **P1** | 4 | HTTP 実行ロジック 6 箇所重複 | 最適化と timeout 対応の実装コスト増 | 低 |
| **P2** | 5 | `numToAlphabet` の前置連結 + `toLower()` | placeholder 多いと微小劣化 | 低 |
| **P2** | 6 | `questionToDaller()` の placeholder 名生成 | 微小 | 低 |
| **P2** | 7 | `rows.toSeq()` の追加走査 | 大量行取得で余分な走査 | 低〜中 |

---

## PostgreSQL / MariaDB との比較

| 項目 | MariaDB / PostgreSQL | Surreal（現状） |
|---|---|---|
| プール待機 | `Deque` + 通知ベース | 同様に改善済み |
| deadline 管理 | `MonoTime` 利用 | 接続取得待ちは利用、HTTP 実行待ちは未適用 |
| 実リクエスト timeout | driver 内で明示設計 | `timeout` 引数が未使用 |
| 初期化コスト | DB 接続確立中心 | `/status` + `DEFINE ...` を接続数ぶん HTTP 実行 |
| フォーマット最適化 | `dbFormat` 改善済み箇所あり | `JsonNode` 経路は未最適化 |

## 次に着手するなら

1. `surreal_impl.nim` に共通 `runSql` ヘルパを作り、timeout・HTTP status・JSON parse・Surreal error 判定を 1 箇所へ寄せる
2. `surreal_open.nim` の bootstrap を 1 回化し、残り接続は軽量に初期化する
3. `surreal_lib.nim` の `dbFormat(JsonNode)` を単一バッファ書き込みへ変更する
