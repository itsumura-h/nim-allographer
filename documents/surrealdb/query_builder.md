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

SurrealDB is a next-generation database built on Rust that can handle all types of data structures-relational, document, and graph-and can run in-memory, on a single node, or in a distributed environment.  
It's response is JSON and allographer return as `JsonNode`.

## Create Connection
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
INSERT INTO `types` [
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
DEBUG SELECT * FROM `types` []

@[
  {
    "bool":true,
    "datetime":"2023-06-05T12:05:07Z",
    "float":3.14,
    "id":"types:9nxye3dons0juyelv5if",
    "int":1,
    "string":"alice"
    },
  {
    "bool":false,
    "datetime":"2023-06-06T12:05:07Z"
    ,"float":1.11,
    "id":"types:tw9iqdycdz9h1egtjkwb",
    "int":2,
    "string":"bob"
  }
]
```

### first
Retrieving a single row from a table. This returns `Option[JsonNode]`

```nim
let res = surreal.table("types").first().await
if res.isSome():
  echo firstRes.get()
```

```nim
DEBUG SELECT * FROM `types` LIMIT 1 []

{
  "bool":true,
  "datetime":"2023-06-05T12:08:47Z",
  "float":3.14,
  "id":"types:64t0w6gpnye7tdf083ch",
  "int":1,
  "string":"alice"
}
```

### find
Retrieve a single row by id. This returns `Option[JsonNode]`
id should be `SurrealId` type.
https://itsumura-h.github.io/nim-allographer/query_builder/surreal/surreal_types.html#SurrealId

```nim
let id = SurrealId.new("types:64t0w6gpnye7tdf083ch")
let res = surreal.table("types").find(id).await
if res.isSome():
  echo res.get()
```

```nim
DEBUG SELECT * FROM `types` WHERE `id` = ? LIMIT 1 ["types:64t0w6gpnye7tdf083ch"]

{
  "bool":true,
  "datetime":"2023-06-05T12:08:47Z",
  "float":3.14,
  "id":"types:64t0w6gpnye7tdf083ch",
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
  echo res.get().pretty()
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
