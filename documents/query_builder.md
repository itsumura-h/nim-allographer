Example: Query Builder
===
[back](../README.md)

## index
<!--ts-->
   * [Example: Query Builder](#example-query-builder)
      * [index](#index)
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
      * [Raw_SQL](#raw_sql)
      * [Aggregates](#aggregates)
      * [Transaction](#transaction)

<!-- Added by: root, at: Wed Sep  8 15:38:17 UTC 2021 -->

<!--te-->
---

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

var rows = await(
            rdb.table("test")
            .select("id", "float", "char", "datetime", "null", "is_admin")
            .get()
          )
          .orm(Typ)
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
let response = await rdb.table("test").get().orm(Typ)
assert response.len == 0

let response = await rdb.raw("select * from users").getRaw().orm(Typ)
assert response.len == 0

let response = await rdb.table("test").find(1).orm(Typ)
assert response.type == Option[Typ]
assert response.isSome == false

let response = await rdb.table("test").first().orm(Typ)
assert response.type == Option[Typ]
assert response.isSome == false
```

### get
Retrieving all row from a table
```nim
let users = await rdb.table("users").get()
for user in users:
  echo user["name"]
```

### first
Retrieving a single row from a table. This returns `Option[JsonNode]`
```nim
let user = await rdb
          .table("users")
          .where("name", "=", "John")
          .first()
if user.isSome:
  echo user.get["name"]
```

### find
Retrieve a single row by its primary key. This returns `Option[JsonNode]`
```nim
let user = await rdb.table("users").find(1)
if user.isSome:
  echo user.get["name"]
```

If the column name of a promary key is not "id", specify this in 2nd arg of `find`
```nim
let user = await rdb.table("users").find(1, "user_id")
if user.isSome:
  echo user.get["name"]
```

### join
```nim
let users = await rdb
            .table("users")
            .select("users.id", "contacts.phone", "orders.price")
            .join("contacts", "users.id", "=", "contacts.user_id")
            .join("orders", "users.id", "=", "orders.user_id")
            .get()
```

### where
```nim
let users = await rdb.table("users").where("age", ">", 25).get()
```

### orWhere
```nim
let users = await rdb
            .table("users")
            .where("age", ">", 25)
            .orWhere("name", "=", "John")
            .get()
```

### whereBetween
```nim
let users = await rdb
            .table("users")
            .whereBetween("age", [25, 35])
            .get()
```

### whereNotBetween
```nim
let users = await rdb
            .table("users")
            .whereNotBetween("age", [25, 35])
            .get()
```

### whereIn
```nim
let users = await rdb
            .table("users")
            .whereIn("id", @[1, 2, 3])
            .get()
```

### whereNotIn
```nim
let users = await rdb
            .table("users")
            .whereNotIn("id", @[1, 2, 3])
            .get()
```

### whereNull
```nim
let users = await rdb
            .table("users")
            .whereNull("updated_at")
            .get()
```

### groupBy_having
```nim
let users = await rdb
            .table("users")
            .group_by("count")
            .having("count", ">", 100)
            .get()
```

### orderBy
```nim
let users = await rdb
            .table("users")
            .orderBy("name", Desc)
            .get()
```
2nd arg of `orderBy` is Enum. `Desc` or `Asc`


### limit_offset
```nim
let users = await rdb
            .table("users")
            .offset(10)
            .limit(5)
            .get()
```

### paginate
```nim
rdb.table("users").delete(2)
let users = await rdb
            .table("users")
            .select("id", "name")
            .paginate(3, 1)
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
var users = await rdb.table("users").select("id", "name").fastPaginate(3)

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
users = await rdb.table("users")
        .select("id", "name")
        .fastPaginateNext(3, users["nextId"].getInt)

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
users = await rdb.table("users")
        .select("id", "name")
        .fastPaginateBack(3, users["previousId"].getInt)

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

rdb
.table("users")
.insert(%*{
  "name": "John",
  "email": "John@gmail.com"
})

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

>> INSERT INTO users (name, email, address) VALUES ("John", "John@gmail.com", "London")
>> INSERT INTO users (name, email, address) VALUES ("Paul", "Paul@gmail.com", "London")
>> INSERT INTO users (name, birth_date, address) VALUES ("George", "1960-1-1", "London")
```

### Return ID Insert
```nim
import allographer/query_builder

echo rdb
.table("users")
.insertId(%*{
  "name": "John",
  "email": "John@gmail.com"
})

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

>> UPDATE users SET name = "Mick", address = "NY" WHERE id = 100
```

## DELETE
[to index](#index)

```nim
import allographer/query_builder

rdb
.table("users")
.delete(1)

>> DELETE FROM users WHERE id = 1
```

If column name of primary key is not exactory "id", you can specify it's name.

```nim
import allographer/query_builder

rdb
.table("users")
.delete(1, key="user_id")

>> DELETE FROM users WHERE user_id = 1
```

```nim
import allographer/query_builder

rdb
.table("users")
.where("address", "=", "London")
.delete()

>> DELETE FROM users WHERE address = "London"
```

## Plain Response
[to index](#INDEX)

`Plain` response doesn't have it's column name but it run faster than `JsonNode` response

```nim
echo rdb.table("users").get()
>> @[
  %*{"id": 1, "name": "user1", "email": "user1@gmail.com"},
  %*{"id": 2, "name": "user2", "email": "user2@gmail.com"},
  %*{"id": 3, "name": "user3", "email": "user3@gmail.com"}
]

echo rdb.table("users").getPlain()
>> @[
  @["1", "user1", "user1@gmail.com"],
  @["2", "user2", "user2@gmail.com"],
  @["3", "user3", "user3@gmail.com"],
]
```

```nim
echo rdb.table("users").find(1)
>> %*{"id": 1, "name": "user1", "email": "user1@gmail.com"}

echo rdb.table("users").findPlain(1)
>> @["1", "user1", "user1@gmail.com"]
```

```nim
echo rdb.table("users").first()
>> %*{"id": 1, "name": "user1", "email": "user1@gmail.com"}

echo rdb.table("users").firstPlain()
>> @["1", "user1", "user1@gmail.com"]
```

## Raw_SQL
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
echo rdb.raw(sql).getRaw()
```
```nim
let sql = "UPDATE users SET name='John' where id = ?"
rdb.raw(sql, "1").exec()
```

## Aggregates
[to index](#index)

Except of `count`, these functions return `Option` type.

```nim
import allographer/query_builder

echo rdb.table("users").count()
>> 10       # int

let response = await rdb.table("users").max("name")
if response.isSome:
  echo response.get
>> "user9"  # string

let response = await rdb.table("users").max("id")
if response.isSome:
  echo response.get
>> "10"     # string

let response = await rdb.table("users").min("name")
if response.isSome:
  echo response.get
>> "user1"  # string

let response = await rdb.table("users").min("id")
if response.isSome:
  echo response.get
>> "1"      # string

let response = await rdb.table("users").avg("id")
if response.isSome:
  echo response.get
>> 5.5      # float

let response = await rdb.table("users").sum("id")
if response.isSome:
  echo response.get
>> 55.0     # float
```

## Transaction
[to index](#index)

```nim
transaction:
  var user = await rdb.table("users").select("id").where("name", "=", "user3").first()
  if user.isSome:
    var id = user.get["id"].getInt()
    echo id
  user = await rdb.table("users").select("name", "email").find(id)
  if user.isSome:
    echo user.get
```
If all code in transaction block success, `COMMIT` is run otherwise `ROLLBACK`
