Example: Query Builder for RDB
===
[back](../../README.md)

## index
<!--ts-->
* [Example: Query Builder for RDB](#example-query-builder-for-rdb)
   * [index](#index)
   * [Create Connection](#create-connection)
   * [SELECT](#select)
      * [return JsonNode](#return-jsonnode)
      * [return Object](#return-object)
      * [get](#get)
      * [first](#first)
      * [find](#find)
      * [join](#join)
      * [where](#where)
      * [orWhere](#orwhere)
      * [whereBetween](#wherebetween)
      * [whereNotBetween](#wherenotbetween)
      * [whereIn](#wherein)
      * [whereNotIn](#wherenotin)
      * [whereNull](#wherenull)
      * [groupBy_having](#groupby_having)
      * [orderBy](#orderby)
      * [limit_offset](#limit_offset)
      * [paginate](#paginate)
      * [fastPaginate](#fastpaginate)
   * [INSERT](#insert)
      * [Return ID Insert](#return-id-insert)
   * [UPDATE](#update)
   * [DELETE](#delete)
   * [Plain Response](#plain-response)
   * [Raw SQL](#raw-sql)
   * [Aggregates](#aggregates)
   * [Transaction](#transaction)

<!-- Created by https://github.com/ekalinin/github-markdown-toc -->
<!-- Added by: root, at: Mon Jul 17 06:30:00 UTC 2023 -->

<!--te-->
---

## Create Connection
```nim
import allographer/connection

let maxConnections = 95
let timeout = 30
let rdb = dbOpen(PostgreSql, "database", "user", "password" "localhost", 5432, maxConnections, timeout)

# also available
# let rdb = dbOpen(Sqlite3, "/path/to/db/sqlite3.db", maxConnections=maxConnections, timeout=timeout)
# let rdb = dbOpen(MySQL, "database", "user", "password" "localhost", 3306, maxConnections, timeout)
# let rdb = dbOpen(MariaDB, "database", "user", "password" "localhost", 3306, maxConnections, timeout)
```

## SELECT
[to index](#index)

When it returns following table

|id|float|char|datetime|null|is_admin|
|---|---|---|---|---|---|
|1|3.14|char|2019-01-01 12:00:00.1234||1|

### return JsonNode
```nim
import allographer/query_builder

echo rdb.table("test")
    .select("id", "float", "char", "datetime", "null", "is_admin")
    .get()
    .await
```

```nim
>> @[
  {
    "id": 1,                                # JInt
    "float": 3.14,                          # JFloat
    "char": "char",                         # JString
    "datetime": "2019-01-01 12:00:00.1234", # JString
    "null": null                            # JNull
    "is_admin": true                        # JBool
  }
]
```

### return Object
If object is defined and set arg of get/getRaw/first/find, response will be object as ORM

```nim
import allographer/query_builder

type Typ = ref object
  id: int
  float: float
  char: string
  datetime: string
  null: string
  is_admin: bool

var rows = rdb.table("test")
          .select("id", "float", "char", "datetime", "null", "is_admin")
          .get(Typ)
          .await
```

```nim
echo rows[0].id
>> 1                            # int

echo rows[0].float
>> 3.14                         # float

echo rows[0].char
>> "char"                       # string

echo rows[0].datetime
>> "2019-01-01 12:00:00.1234"   # string

echo rows[0].null
>> ""                           # string

echo rows[0].is_admin
>> true                         # bool
```

If DB response is empty, `get` and `getRaw` return empty seq, `find` and `first` return optional object.
```nim
let response = await rdb.table("test").get(Typ)
assert response.len == 0

let response = await rdb.raw("select * from users").getRaw(Typ)
assert response.len == 0

let response = await rdb.table("test").find(1, Typ)
assert response.type == Option[Typ]
assert response.isSome == false

let response = await rdb.table("test").first(Typ)
assert response.type == Option[Typ]
assert response.isSome == false
```

### get
Retrieving all row from a table
```nim
let users = rdb.table("users").get().await
for user in users:
  echo user["name"]
```

### first
Retrieving a single row from a table. This returns `Option[JsonNode]`
```nim
let user = rdb
          .table("users")
          .where("name", "=", "John")
          .first()
          .await
if user.isSome:
  echo user.get["name"]
```

### find
Retrieve a single row by its primary key. This returns `Option[JsonNode]`
```nim
let user = rdb.table("users").find(1).await
if user.isSome:
  echo user.get["name"]
```

If the column name of a promary key is not "id", specify this in 2nd arg of `find`
```nim
let user = rdb.table("users").find(1, "user_id").await
if user.isSome:
  echo user.get["name"]
```

### join
```nim
let users = rdb
          .table("users")
          .select("users.id", "contacts.phone", "orders.price")
          .join("contacts", "users.id", "=", "contacts.user_id")
          .join("orders", "users.id", "=", "orders.user_id")
          .get()
          .await
```

### where
```nim
let users = rdb.table("users").where("age", ">", 25).get().await
```

### orWhere
```nim
let users = rdb
          .table("users")
          .where("age", ">", 25)
          .orWhere("name", "=", "John")
          .get()
          .await
```

### whereBetween
```nim
let users = rdb
          .table("users")
          .whereBetween("age", [25, 35])
          .get()
          .await
```

### whereNotBetween
```nim
let users = rdb
          .table("users")
          .whereNotBetween("age", [25, 35])
          .get()
          .await
```

### whereIn
```nim
let users = rdb
          .table("users")
          .whereIn("id", @[1, 2, 3])
          .get()
          .await
```

### whereNotIn
```nim
let users = rdb
            .table("users")
            .whereNotIn("id", @[1, 2, 3])
            .get()
            .await
```

### whereNull
```nim
let users = rdb
            .table("users")
            .whereNull("updated_at")
            .get()
            .await
```

### groupBy_having
```nim
let users = rdb
            .table("users")
            .group_by("count")
            .having("count", ">", 100)
            .get()
            .await
```

### orderBy
```nim
let users = rdb
            .table("users")
            .orderBy("name", Desc)
            .get()
            .await
```
2nd arg of `orderBy` is Enum. `Desc` or `Asc`


### limit_offset
```nim
let users = rdb
            .table("users")
            .offset(10)
            .limit(5)
            .get()
            .await
```

### paginate
```nim
rdb.table("users").delete(2)
let users = rdb
            .table("users")
            .select("id", "name")
            .paginate(3, 1)
            .await
```
arg1... Numer of items per page  
arg2... Numer of page(option)(1 is set by default)

```nim
echo users
>> {
  "count":3,
  "currentPage":[
    {"id":1,"name":"user1"},
    {"id":3,"name":"user3"},
    {"id":4,"name":"user4"}
  ],
  "hasMorePages":true,
  "lastPage":3,
  "nextPage":2,
  "perPage":3,
  "previousPage":1,
  "total":9
}
```

|ATTRIBUTE|DESCRIPTION|
|---|---|
|count|number of results on the current page|
|currentPage|results of current page|
|hasMorePages|Returns `True` if there is more pages else `False`|
|lastPage|The number of the last page|
|nextPage|The number of the next page if it exists else equel to lastPage|
|perPage|The number of results per page|
|previousPage|The number of the previous page if it exists else 1|
|total|The total number of results|


### fastPaginate
It run faster than `paginate()` because it doesn't use `offset`.

|sample URL|usage|result items|
|---|---|---|
|/users?items=5|`fastPaginate(5)`|1,2,3,4,5|
|/users?items=5&since=6|`fastPaginateNext(5, 6)`|6,7,8,9,10|
|/users?items=5&until=5|`fastPaginateBack(5, 5)`|1,2,3,4,5|

```nim
proc fastPaginate(this:Rdb, display:int, key="id", order:Order=Asc): JsonNode
```  
- display...Numer of items per page.  
- key...Name of a primary key column (option). default is `id`.  
- order...Asc or Desc (option). default is `Asc`.

```nim
proc fastPaginateNext(this:Rdb, display:int, id:int, key="id", order:Order=Asc): JsonNode

proc fastPaginateBack(this:Rdb, display:int, id:int, key="id", order:Order=Asc): JsonNode
```
- display...Numer of items per page.  
- id...Value of primary key. It should be larger than 0.  
- key...Name of a primary key column (option). default is `id`.
- order...Asc or Desc (option). default is `Asc`.

```nim
var users = rdb.table("users").select("id", "name").fastPaginate(3).await

>> {
  "previousId":0,
  "hasPreviousId": false,
  "currentPage":[
    {"id":1,"name":"user1"},
    {"id":2,"name":"user2"},
    {"id":3,"name":"user3"},
  ],
  "nextId":4,
  "hasNextId": true
}
```
```nim
users = rdb.table("users")
        .select("id", "name")
        .fastPaginateNext(3, users["nextId"].getInt)
        .await

>> {
  "previousId":4,
  "hasPreviousId": true,
  "currentPage":[
    {"id":5,"name":"user5"},
    {"id":6,"name":"user6"},
    {"id":7,"name":"user7"}
  ],
  "nextId":8,
  "hasNextId": true
}
```
```nim
users = rdb.table("users")
        .select("id", "name")
        .fastPaginateBack(3, users["previousId"].getInt)
        .await

>> {
  "previousId":0,
  "hasPreviousId": false,
  "currentPage":[
    {"id":1,"name":"user1"},
    {"id":2,"name":"user2"},
    {"id":3,"name":"user3"},
  ],
  "nextId":4,
  "hasNextId": true
}
```

order Desc
```nim
echo rdb.table("users")
      .select("id", "name")
      .fastPaginateNext(3, 5, order=Desc)
      .await

>> {
  "previousId":6,
  "hasPreviousId":true,
  "currentPage":[
    {"id":5,"name":"user5"},
    {"id":4,"name":"user4"},
    {"id":3,"name":"user3"}
  ],
  "nextId":2,
  "hasNextId":true
}
```

paginate with `join` and `where`
```nim
echo rdb.table("users")
      .select("users.id", "users.name", "users.auth_id")
      .join("auth", "auth.id", "=", "users.auth_id")
      .where("auth.id", "=", 2)
      .fastPaginate(3, key="users.id")
      .await

>> {
  "previousId":0,
  "hasPreviousId":false,
  "currentPage":[
    {"id":4,"name":"user4","auth_id":2},
    {"id":6,"name":"user6","auth_id":2},
    {"id":8,"name":"user8","auth_id":2}
  ],
  "nextId":8,
  "hasNextId":true
}
```


## INSERT
[to index](#index)

```nim
import allographer/query_builder

rdb.table("users").insert(%*{
  "name": "John",
  "email": "John@gmail.com"
})
.await

>> INSERT INTO users (name, email) VALUES ("John", "John@gmail.com")
```
```nim
import allographer/query_builder

rdb.table("users").insert(
  @[
    %*{"name": "John", "email": "John@gmail.com", "address": "London"},
    %*{"name": "Paul", "email": "Paul@gmail.com", "address": "London"},
    %*{"name": "George", "email": "George@gmail.com", "address": "London"},
  ]
)
.await

>> INSERT INTO users (name, email, address) VALUES ("John", "John@gmail.com", "London"), ("Paul", "Paul@gmail.com", "London"), ("George", "George@gmail.com", "London")
```
```nim
import allographer/query_builder

rdb.table("users").inserts(
  @[
    %*{"name": "John", "email": "John@gmail.com", "address": "London"},
    %*{"name": "Paul", "email": "Paul@gmail.com", "address": "London"},
    %*{"name": "George", "birth_date": "1943-02-25", "address": "London"},
  ]
)
.await

>> INSERT INTO users (name, email, address) VALUES ("John", "John@gmail.com", "London")
>> INSERT INTO users (name, email, address) VALUES ("Paul", "Paul@gmail.com", "London")
>> INSERT INTO users (name, birth_date, address) VALUES ("George", "1960-1-1", "London")
```

### Return ID Insert
```nim
import allographer/query_builder

echo rdb.table("users").insertId(%*{
  "name": "John",
  "email": "John@gmail.com"
})
.await

>> INSERT INTO users (name, email) VALUES ("John", "John@gmail.com")
>> 1 # ID of new row is return
```
```nim
import allographer/query_builder

echo rdb.table("users").insertId(
  @[
    %*{"name": "John", "email": "John@gmail.com", "address": "London"},
    %*{"name": "Paul", "email": "Paul@gmail.com", "address": "London"},
    %*{"name": "George", "email": "George@gmail.com", "address": "London"},
  ]
)
.await

>> INSERT INTO users (name, email, address) VALUES ("John", "John@gmail.com", "London"), ("Paul", "Paul@gmail.com", "London"), ("George", "George@gmail.com", "London")
>> @[1, 2] # Seq of ID of new row is return
```
```nim
import allographer/query_builder

echo rdb.table("users").insertsID(
  @[
    %*{"name": "John", "email": "John@gmail.com", "address": "London"},
    %*{"name": "Paul", "email": "Paul@gmail.com", "address": "London"},
    %*{"name": "George", "birth_date": "1943-02-25", "address": "London"},
  ]
)
.await

>> INSERT INTO users (name, email, address) VALUES ("John", "John@gmail.com", "London")
>> INSERT INTO users (name, email, address) VALUES ("Paul", "Paul@gmail.com", "London")
>> INSERT INTO users (name, birth_date, address) VALUES ("George", "1960-1-1", "London")
>> @[1, 2, 3] # Seq of ID of new row is return
```


## UPDATE
[to index](#index)

```nim
import allographer/query_builder

rdb
.table("users")
.where("id", "=", 100)
.update(%*{"name": "Mick", "address": "NY"})
.await

>> UPDATE users SET name = "Mick", address = "NY" WHERE id = 100
```

## DELETE
[to index](#index)

```nim
import allographer/query_builder

rdb
.table("users")
.delete(1)
.await

>> DELETE FROM users WHERE id = 1
```

If column name of primary key is not exactory "id", you can specify it's name.

```nim
import allographer/query_builder

rdb
.table("users")
.delete(1, key="user_id")
.await

>> DELETE FROM users WHERE user_id = 1
```

```nim
import allographer/query_builder

rdb
.table("users")
.where("address", "=", "London")
.delete()
.await

>> DELETE FROM users WHERE address = "London"
```

## Plain Response
[to index](#INDEX)

`Plain` response doesn't have it's column name but it run faster than `JsonNode` response

```nim
echo rdb.table("users").get().await
>> @[
  %*{"id": 1, "name": "user1", "email": "user1@gmail.com"},
  %*{"id": 2, "name": "user2", "email": "user2@gmail.com"},
  %*{"id": 3, "name": "user3", "email": "user3@gmail.com"}
]

echo rdb.table("users").getPlain().await
>> @[
  @["1", "user1", "user1@gmail.com"],
  @["2", "user2", "user2@gmail.com"],
  @["3", "user3", "user3@gmail.com"],
]
```

```nim
echo rdb.table("users").find(1).await
>> %*{"id": 1, "name": "user1", "email": "user1@gmail.com"}

echo rdb.table("users").findPlain(1).await
>> @["1", "user1", "user1@gmail.com"]
```

```nim
echo rdb.table("users").first().await
>> %*{"id": 1, "name": "user1", "email": "user1@gmail.com"}

echo rdb.table("users").firstPlain().await
>> @["1", "user1", "user1@gmail.com"]
```

## Raw SQL
[to index](#INDEX)

```nim
import allographer/query_builder

let sql = """
SELECT ProductName
  FROM Product 
  WHERE Id IN (SELECT ProductId 
                FROM OrderItem
               WHERE Quantity > 100)
"""
echo rdb.raw(sql).get().await
echo rdb.raw(sql).getPlain().await
echo rdb.raw(sql).first().await
echo rdb.raw(sql).firstPlain().await
```
```nim
let sql = "UPDATE users SET name = ? where id = ?"
rdb.raw(sql, "John", "1").exec().await
```

## Aggregates
[to index](#index)

Except of `count`, these functions return `Option` type.

```nim
import allographer/query_builder

echo rdb.table("users").count()
>> 10       # int

let response = await rdb.table("users").max("name").await
if response.isSome:
  echo response.get
>> "user9"  # string

let response = await rdb.table("users").max("id").await
if response.isSome:
  echo response.get
>> "10"     # string

let response = await rdb.table("users").min("name").await
if response.isSome:
  echo response.get
>> "user1"  # string

let response = await rdb.table("users").min("id").await
if response.isSome:
  echo response.get
>> "1"      # string

let response = await rdb.table("users").avg("id").await
if response.isSome:
  echo response.get
>> 5.5      # float

let response = await rdb.table("users").sum("id").await
if response.isSome:
  echo response.get
>> 55.0     # float
```

## Transaction
[to index](#index)

```nim
transaction:
  var user = rdb.table("users").select("id").where("name", "=", "user3").first().await
  if user.isSome:
    var id = user.get["id"].getInt()
    echo id
  user = rdb.table("users").select("name", "email").find(id).await
  if user.isSome:
    echo user.get
```
If all code in transaction block success, `COMMIT` is run otherwise `ROLLBACK`
