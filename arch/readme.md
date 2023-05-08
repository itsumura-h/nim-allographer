```
|-- interface
`-- lib
    |-- def
    |-- proc1
    `-- proc2
```

interface -> lib/def
interface -> lib/proc1
interface -> lib/proc2

proc1 -> def
proc2 -> def

---

query_builder/exec
```
get() -> getAllRows() -> async_db.query()
first() -> getRow() -> async_db.query()
find() -> getRow() -> async_db.query()
insert() -> async_db.exec()
update() -> async_db.exec()
delete() -> async_db.exec()
```

async/async_db
```
query() -> sqlite.query()
exec() -> sqlite.exec()
```

↓

query_builder/exec
```
get() -> database.get()
first() -> database.first()
find() -> database.find()
insert() -> database.insert()
update() -> database.update()
delete() -> database.delete()
```
- コネクションの選択、レスポンスの整形

databases/database
```
get() -> sqlite.query() / surreal.get()
first() -> sqlite.query() / surreal.get()
find() -> sqlite.query() / surreal.get()
insert() -> sqlite.exec() / surreal.get()
update() -> sqlite.exec() / surreal.get()
delete() -> sqlite.exec() / surreal.get()
```
- 各DBへの処理の振り分け

- [x] base.nim -> types.nim
- [x] baseEnv.nim -> env.nim
- [x] async/async_db.nim -> databases/database.nim
- [x] async/database/base.nim -> databases/database_types.nim
- [ ] databases/database/impls / libs / rdb -> databases/impls / libs / rdb


## Surreal

```nim
import std/asyncdispatch
import std/httpclient
import std/times
import std/strformat
import std/base64
import std/strutils
import std/json


proc dbopen*(database: string = "", user: string = "", password: string = "", host: string = "", port: int32 = 0, maxConnections: int = 1, timeout=30): Connections =
  var pools = newSeq[Pool](maxConnections)
  for i in 0..<maxConnections:
    let client = newAsyncHttpClient()
    var headers = newHttpHeaders(true)
    headers["NS"] = database.split(":")[0]
    headers["DB"] = database.split(":")[1]
    headers["Accept"] = "application/json"
    headers["Authorization"] = "Basic " & base64.encode(user & ":" & password)
    client.headers = headers

    pools[i] = Pool(
      surrealConn: SurrealConn(conn: client, host:host, port:port),
      isBusy: false,
      createdAt: getTime().toUnix(),
    )
  result = Connections(
    pools: pools,
    timeout: timeout
  )

proc query*(db:SurrealConn, query: string, args: seq[string], timeout:int):Future[(seq[Row], DbRows)] {.async.} =
  assert(not db.conn.isNil, "Database not connected.")
  var dbRows: DbRows
  var rows = newSeq[seq[string]]()
  let resp = await db.conn.post(&"{db.host}:{db.port}/sql", query)
  let body = resp.body.await
  rows.add(
    @[$body.parseJson[0]]
  )
  return (rows, dbRows)


proc exec*(db:SurrealConn, query: string, args: seq[string], timeout:int) {.async.} =
  assert(not db.conn.isNil, "Database not connected.")
  let resp = await db.conn.post(&"{db.host}:{db.port}/sql", query)
  if resp.code != Http200:
    dbError(resp.body.await)
```
