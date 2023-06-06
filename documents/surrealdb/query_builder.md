Example: Query Builder for SurrealDB
===
[back](../../README.md)

## index
<!--ts-->
<!--te-->

---

## About SurrealDB
[SurrealDB official docs](https://surrealdb.com/docs)  
[SurrealDB Github](https://github.com/surrealdb/surrealdb)

SurrealDB is a next-generation database built on Rust that can handle all type of data structures-relational, document, and graph-and can run in-memory, on a single node, or in a distributed environment.  
It's response is JSON and allographer return as `JsonNode`.

## Create Connection
[to index](#index)

```nim
import allographer/connection

let maxConnections = 95
let timeout = 30
let surreal = dbOpen(SurrealDb, "test", "test", "user", "pass", "http://surreal", 8000, maxConnections, timeout, true, true).await()
```

## SELECT
[to index](#index)

When it returns following table

```sql
INSERT INTO `type` [
  {"bool":true,"string":"alice","int":1,"float":3.14,"datetime":"2023-06-05T11:58:42+00:00"},
  {"bool":false,"string":"bob","int":2,"float":1.11,"datetime":"2023-06-06T11:58:42+00:00"}
]
```

|bool|string|int|float|datetime|
|---|---|---|---|---|
|true|alice|1|3.14|2023-06-05T11:58:42+00:00
|false|bob|2|1.11|2023-06-06T11:58:42+00:00


### get
Retrieving all row from a table

```nim
import allographer/query_builder

echo surreal.table("user").get()
```

```nim
DEBUG SELECT * FROM `type` []

@[
  {
    "bool":true,
    "datetime":"2023-06-05T12:05:07Z",
    "float":3.14,
    "id":"type:9nxye3dons0juyelv5if",
    "int":1,
    "string":"alice"
    },
  {
    "bool":false,
    "datetime":"2023-06-06T12:05:07Z"
    ,"float":1.11,
    "id":"type:tw9iqdycdz9h1egtjkwb",
    "int":2,
    "string":"bob"
  }
]
```

### first
Retrieving a single row from a table. This returns `Option[JsonNode]`

```nim
let res = surreal.table("type").first().await
if res.isSome():
  echo firstRes.get()
```

```nim
DEBUG SELECT * FROM `type` LIMIT 1 []

{
  "bool":true,
  "datetime":"2023-06-05T12:08:47Z",
  "float":3.14,
  "id":"type:64t0w6gpnye7tdf083ch",
  "int":1,
  "string":"alice"
}
```

### find
Retrieve a single row by id. This returns `Option[JsonNode]`  
Id should be `SurrealId` type.  
https://itsumura-h.github.io/nim-allographer/query_builder/surreal/surreal_types.html#SurrealId

```nim
let id = SurrealId.new("type:64t0w6gpnye7tdf083ch")
let res = surreal.table("type").find(id).await
if res.isSome():
  echo res.get()
```

```nim
DEBUG SELECT * FROM `type` WHERE `id` = ? LIMIT 1 ["type:64t0w6gpnye7tdf083ch"]

{
  "bool":true,
  "datetime":"2023-06-05T12:08:47Z",
  "float":3.14,
  "id":"type:64t0w6gpnye7tdf083ch",
  "int":1,
  "string":"alice"
}
```

### where
user
|id|name|email|
|---|---|---|
|user:2jrkvgwpdr02p71sfu1f|alice|alice@example.com|

```nim
let res = surreal.table("user").where("name", "=", "alice").first().await
if res.isSome():
  echo res.get()
```

```nim
{
  "email": "alice@example.com",
  "id": "user:iss5w0fp4x3o08t2br3s",
  "name": "alice"
}
```

### fetch
Fetch and replace records with the remote record data.  
It is used for retrieve relational tables.

auth
|id|name|
|---|---|
|auth:pl93k823yinrm8hzip22|admin|
|auth:e3is4h0txnn6cpmcuoca|editor|

user
|id|name|email|auth|
|---|---|---|---|
|user:2jrkvgwpdr02p71sfu1f|alice|alice@example.com|auth:pl93k823yinrm8hzip22|

```nim
let alice = surreal.table("user").where("auth.name", "=", "admin").fetch("auth").first().await
if alice.isSome():
  echo alice.get()
```

```nim
{
  "auth": {
    "id": "auth:ayp1w74u5oo8m4w2neyi",
    "name": "admin"
  },
  "email": "alice@example.com",
  "id": "user:5d7pgwag7i7uymigdako",
  "name": "alice"
}
```

## INSERT
[to index](#index)

### insert single row
```nim
surreal.table("type").insert(%*{
  "bool":true,
  "string": "alice",
  "int": 1,
  "float": 3.14,
  "datetime": now().format("yyyy-MM-dd'T'HH:mm:sszzz")
})
.await
```

### insert rows
```nim
surreal.table("type").insert(%*[
  {
    "bool":true,
    "string": "alice",
    "int": 1,
    "float": 3.14,
    "datetime": now().format("yyyy-MM-dd'T'HH:mm:sszzz")
  },
  {
    "bool":false,
    "string": "bob",
    "int": 2,
    "float": 1.11,
    "datetime": (now() + initDuration(days=1)).format("yyyy-MM-dd'T'HH:mm:sszzz")
  }
])
.await
```

### insertId
```nim
let id:SurrealId = surreal.table("type").insertId(%*{
  "bool":true,
  "string": "alice",
  "int": 1,
  "float": 3.14,
  "datetime": now().format("yyyy-MM-dd'T'HH:mm:sszzz")
})
.await

echo id.rawId()
```

```nim
type:9nxye3dons0juyelv5if
```

## UPDATE
[to index](#index)

```nim
let id = surreal.table("type").insertId(%*{
  "bool":true,
  "string": "alice",
  "int": 1,
  "float": 3.14,
  "datetime": now().format("yyyy-MM-dd'T'HH:mm:sszzz")
})
.await

surreal.table("type").where("id", "=", id).update(%*{"string": "bob"}).await
let res = surreal.table("type").find(id).await
if res.isSome():
  echo res.get()
```

```nim
{
  "bool":true,
  "datetime":"2023-06-06T02:34:25Z",
  "float":3.14,
  "id":"type:hp0aqct78btlcyr1ho06",
  "int":1,
  "string":"bob"
}
```

## DELETE
[to index](#index)


## delete all
```nim
let id = surreal.table("type").insertId(%*{
  "bool":true,
  "string": "alice",
  "int": 1,
  "float": 3.14,
  "datetime": now().format("yyyy-MM-dd'T'HH:mm:sszzz")
})
.await

surreal.table("type").delete().await
echo surreal.table("type").get().await
```

```nim
@[]
```

## delete row
```nim
surreal.table("type").insert(%*[
  {
    "bool":true,
    "string": "alice",
    "int": 1,
    "float": 3.14,
    "datetime": now().format("yyyy-MM-dd'T'HH:mm:sszzz")
  },
  {
    "bool":false,
    "string": "bob",
    "int": 2,
    "float": 1.11,
    "datetime": (now() + initDuration(days=1)).format("yyyy-MM-dd'T'HH:mm:sszzz")
  }
])
.await

let row = surreal.table("type").where("string", "=", "alice").first().await.get()
let rowId = SurrealId.new(row["id"].getStr())

surreal.table("type").where("id", "=", rowId).delete().await
echo surreal.table("type").get().await
```

```nim
@[
  {
    "bool":false,
    "datetime":"2023-06-07T03:39:14Z",
    "float":"1.11",
    "id":"type:y93d6ig6iyrvcez0lc9k",
    "int":2,
    "string":"bob"
  }
]
```

## Raw_SQL
[to index](#INDEX)

`raw()` returns `RawQuerySurrealDb` type.  
You can use `get()`, `exec()` and `info()` for raw query.  
`get()` returns all rows of result.  
`exec()` executes query and not return any variables.  
`info()` executes query and returns all data of response.

```nim
let define = """
REMOVE TABLE type;
DEFINE TABLE type SCHEMAFULL;
DEFINE FIELD index ON TABLE type TYPE int;
DEFINE INDEX types_index ON TABLE type COLUMNS index UNIQUE;
DEFINE FIELD bool ON TABLE type TYPE bool;
DEFINE FIELD datetime ON TABLE type TYPE datetime;
DEFINE FIELD float ON TABLE type TYPE float;
DEFINE FIELD int ON TABLE type TYPE int;
DEFINE FIELD string ON TABLE type TYPE string;
"""
surreal.raw(define).exec().await()

echo surreal.raw("INFO FOR TABLE type").info().await

>> [
  {
    "time":"32.762515ms",
    "status":"OK",
    "result":{
      "ev":{},
      "fd":{
        "bool":"DEFINE FIELD bool ON type TYPE bool",
        "datetime":"DEFINE FIELD datetime ON type TYPE datetime",
        "float":"DEFINE FIELD float ON type TYPE float",
        "index":"DEFINE FIELD index ON type TYPE int",
        "int":"DEFINE FIELD int ON type TYPE int",
        "string":"DEFINE FIELD string ON type TYPE string"
      },
      "ft":{},
      "ix":{
        "types_index":"DEFINE INDEX types_index ON type FIELDS index UNIQUE"
      }
    }
  }
]

var rows = surreal.raw("SELECT * FROM type").get().await
let max = rows.len + 1

surreal.raw(
  """
    CREATE type CONTENT {
      index: ?,
      bool: true,
      datetime: ?,
      float: 1.11,
      int: 1,
      string: "aaa"
    }
  """,
  $max, now().format("yyyy-MM-dd'T'HH:mm:sszzz")
)
.exec()
.await

rows = surreal.raw("SELECT * FROM type").get().await
echo rows

>> @[
  {
    "bool":true,
    "datetime":"2023-06-06T04:01:32Z",
    "float":1.11,
    "id":"type:f1qxioacts8cydbmchpy",
    "index":1,
    "int":1,
    "string":"aaa"
  }
]
```

## Aggregates
[to index](#INDEX)

### count
```nim
surreal.table("user").insert(%*[
  {"name": "alice", "email": "alice@example.com"},
  {"name": "bob", "email": "bob@example.com"},
  {"name": "charlie", "email": "charlie@example.com"},
])
.await

let count = surreal.table("user").count().await
echo count
```

```sh
>> 3
```

### max
```nim
surreal.table("user").insert(%*[
  {"name": "alice", "email": "alice@example.com", "index": 1},
  {"name": "bob", "email": "bob@example.com", "index": 2},
  {"name": "charlie", "email": "charlie@example.com", "index": 3},
])
.await

let max = surreal.table("user").max("index").await
echo max
```

```
>> 3
```

### min
```nim
surreal.table("user").insert(%*[
  {"name": "alice", "email": "alice@example.com", "index": 1},
  {"name": "bob", "email": "bob@example.com", "index": 2},
  {"name": "charlie", "email": "charlie@example.com", "index": 3},
])
.await

let min = surreal.table("user").min("index").await
echo min
```

```
>> 1
```
