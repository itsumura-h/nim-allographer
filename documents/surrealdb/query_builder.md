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

## Create Connection
```nim
import allographer/connection

let maxConnections = 95
let timeout = 30
let surreal = dbOpen(SurrealDb, "test", "test", "user", "pass", "http://surreal", 8000, maxConnections, timeout, true, true).await()
```

## SELECT
[to index](#index)

```nim
import allographer/query_builder

echo surreal.table("")
```
