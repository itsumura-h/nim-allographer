# Very simple PostgreSQL async pool api for nim


## Open a connection:

To open a pool with 10 connections simply use:
```nim
let pg = newAsyncPool("localhost", "user", "password", "dbname", 10)
```

By using a connection pool, 10 connections are opened and when your application makes a query a free connection is taking from the pool. Otherwise your query will wait for a free connection to become available. This allows your application to run any number of queries at once. By default PostgreSQL will accept 100 connections. PostgreSQL can run multiple queries at once as well but they will start impacting each other especially if they read or write to same tables, or you have run out of CPU cores.


You can open a single connection with `db_postgres`'s api:
```nim
let pg = open("localhost", "user", "password", "dbname")
```
But you have to be carefull to not run more then one query at once on the connection.


## Get rows

If running in `{.async.}` funciton use `await`:
```nim
let rows = await pg.rows(sql"SELECT 1")
for row in rows:
  echo row
```

Otherwies you can use `waitFor`:
```nim
let rows = waitFor pg.rows(sql"SELECT 1")
```

You can add multiple paramaters that will be escaped:
```nim
let rows = await pg.rows(sql"SELECT ?, pg_sleep(1);", @["foo"])
```

## Run query without results

You can also run query by ignoring results in `{.async.}` funciton use `await`:
```nim
await pg.exec(sql"UPDATE TABLE foo SET a=1")
```

## Concurency:

Run 10 queries at once:

```nim
let pool = newAsyncPool("localhost", "", "", "test", 2)
var futures = newSeq[Future[seq[Row]]]()
for i in 0..<20:
  futures.add pool.rows(sql"SELECT ?, pg_sleep(1);", @[$i])
for f in futures:
  var res = await f
echo res
```

Run query but don't care about the results or when it will finish:
```nim
asyncCheck pg.exec(sql"UPDATE TABLE foo SET a=1")
```

