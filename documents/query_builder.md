Example: Query Builder
===
[back](../README.md)

## index
- [SELECT](#SELECT)
  - [get](#get)
  - [first](#first)
  - [find](#find)
  - [join](#join)
  - [where](#where)
  - [orWhere](#orWhere)
  - [whereBetween](#whereBetween)
  - [whereNotBetween](#whereNotBetween)
  - [whereIn](#whereIn)
  - [whereNotIn](#whereNotIn)
  - [whereNull](#whereNull)
  - [groupBy](#groupBy)
  - [having](#having)
  - [orderBy](#orderBy)
  - [limit-offset](#limit_offset)
  - [Paginate](#paginate)
  - [fastPaginate](#fastPaginate)

- [INSERT](#INSERT)
- [UPDATE](#UPDATE)
- [DELETE](#DELETE)
- [RAW_SQL](#RAW_SQL)
- [Aggregates](#Aggregates)
- [Transaction](#Transaction)

## SELECT
[to index](#index)

When it returns following table

|id|float|char|datetime|null|is_admin|
|---|---|---|---|---|---|
|1|3.14|char|2019-01-01 12:00:00.1234||1|

### return JsonNode
```nim
import allographer/query_builder

echo RDB().table("test")
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

var rows = RDB().table("test")
          .select("id", "float", "char", "datetime", "null", "is_admin")
          .get(Typ)
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
let response = RDB().table("test").get(Typ)
assert response.len == 0

let response = RDB().raw("select * from users").getRaw(Typ)
assert response.len == 0

let response = RDB().table("test").find(1, Typ)
assert response.type == Option[Typ]

let response = RDB().table("test").first(Typ)
assert response.type == Option[Typ]
```

### get
Retrieving all row from a table
```nim
let users = RDB().table("users").get()
for user in users:
  echo user["name"]
```

### first
Retrieving a single row from a table
```nim
let user = RDB()
            .table("users")
            .where("name", "=", "John")
            .first()
echo user["name"]
```

### find
Retrieve a single row by its primary key
```nim
let user = RDB().table("users").find(1)
echo user["name"]
```

If the column name of a promary key is not "id", specify this in 2nd arg of `find`
```nim
let user = RDB().table("users").find(1, "user_id")
echo user["name"]
```

### join
```nim
let users = RDB()
            .table("users")
            .select("users.id", "contacts.phone", "orders.price")
            .join("contacts", "users.id", "=", "contacts.user_id")
            .join("orders", "users.id", "=", "orders.user_id")
            .get()
```

### where
```nim
let users = RDB().table("users").where("age", ">", 25).get()
```

### orWhere
```nim
let users = RDB()
            .table("users")
            .where("age", ">", 25)
            .orWhere("name", "=", "John")
            .get()
```

### whereBetween
```nim
let users = RDB()
            .table("users")
            .whereBetween("age", [25, 35])
            .get()
```

### whereNotBetween
```nim
let users = RDB()
            .table("users")
            .whereNotBetween("age", [25, 35])
            .get()
```

### whereIn
```nim
let users = RDB()
            .table("users")
            .whereIn("id", @[1, 2, 3])
            .get()
```

### whereNotIn
```nim
let users = RDB()
            .table("users")
            .whereNotIn("id", @[1, 2, 3])
            .get()
```

### whereNull
```nim
let users = RDB()
            .table("users")
            .whereNull("updated_at")
            .get()
```

### groupBy_having
```nim
let users = RDB()
            .table("users")
            .group_by("count")
            .having("count", ">", 100)
            .get()
```

### orderBy
```nim
let users = RDB()
            .table("users")
            .orderBy("name", Desc)
            .get()
```
2nd arg of `orderBy` is Enum. `Desc` or `Asc`


### limit_offset
```nim
let users = RDB()
            .table("users")
            .offset(10)
            .limit(5)
            .get()
```

### paginate
```nim
RDB().table("users").delete(2)
let users = RDB()
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
proc fastPaginate(this:RDB, display:int, key="id", order:Order=Asc): JsonNode
```  
- display...Numer of items per page.  
- key...Name of a primary key column (option). default is `id`.  
- order...Asc or Desc (option). default is `Asc`.

```nim
proc fastPaginateNext(this:RDB, display:int, id:int, key="id", order:Order=Asc): JsonNode

proc fastPaginateBack(this:RDB, display:int, id:int, key="id", order:Order=Asc): JsonNode
```
- display...Numer of items per page.  
- id...Value of primary key. It should be larger than 0.  
- key...Name of a primary key column (option). default is `id`.
- order...Asc or Desc (option). default is `Asc`.

```nim
var users = RDB().table("users").select("id", "name").fastPaginate(3)

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
users = RDB().table("users")
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
users = RDB().table("users")
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
echo RDB().table("users")
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
echo RDB().table("users")
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

RDB()
.table("users")
.insert(%*{
  "name": "John",
  "email": "John@gmail.com"
})

>> INSERT INTO users (name, email) VALUES ("John", "John@gmail.com")
```
```nim
import allographer/query_builder

RDB().table("users").insert(
  [
    %*{"name": "John", "email": "John@gmail.com", "address": "London"},
    %*{"name": "Paul", "email": "Paul@gmail.com", "address": "London"},
    %*{"name": "George", "email": "George@gmail.com", "address": "London"},
  ]
)

>> INSERT INTO users (name, email, address) VALUES ("John", "John@gmail.com", "London"), ("Paul", "Paul@gmail.com", "London"), ("George", "George@gmail.com", "London")
```
```nim
import allographer/query_builder

RDB().table("users").inserts(
  [
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

echo RDB()
.table("users")
.insertID(%*{
  "name": "John",
  "email": "John@gmail.com"
})

>> INSERT INTO users (name, email) VALUES ("John", "John@gmail.com")
>> 1 # ID of new row is return
```
```nim
import allographer/query_builder

echo RDB().table("users").insertID(
  [
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

echo RDB().table("users").insertsID(
  [
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

RDB()
.table("users")
.where("id", "=", 100)
.update(%*{"name": "Mick", "address": "NY"})

>> UPDATE users SET name = "Mick", address = "NY" WHERE id = 100
```

## DELETE
[to index](#index)

```nim
import allographer/query_builder

RDB()
.table("users")
.delete(1)

>> DELETE FROM users WHERE id = 1
```

If column name of primary key is not exactory "id", you can specify it's name.

```nim
import allographer/query_builder

RDB()
.table("users")
.delete(1, key="user_id")

>> DELETE FROM users WHERE user_id = 1
```

```nim
import allographer/query_builder

RDB()
.table("users")
.where("address", "=", "London")
.delete()

>> DELETE FROM users WHERE address = "London"
```

## Plain Response
[to index](#INDEX)

`Plain` response doesn't have it's column name but it run faster than `JsonNode` response

```nim
echo RDB().table("users").get()
>> @[
  %*{"id": 1, "name": "user1", "email": "user1@gmail.com"},
  %*{"id": 2, "name": "user2", "email": "user2@gmail.com"},
  %*{"id": 3, "name": "user3", "email": "user3@gmail.com"}
]

echo RDB().table("users").getPlain()
>> @[
  @["1", "user1", "user1@gmail.com"],
  @["2", "user2", "user2@gmail.com"],
  @["3", "user3", "user3@gmail.com"],
]
```

```nim
echo RDB().table("users").find(1)
>> %*{"id": 1, "name": "user1", "email": "user1@gmail.com"}

echo RDB().table("users").findPlain(1)
>> @["1", "user1", "user1@gmail.com"]
```

```nim
echo RDB().table("users").first()
>> %*{"id": 1, "name": "user1", "email": "user1@gmail.com"}

echo RDB().table("users").firstPlain()
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
echo RDB().raw(sql).getRaw()
```
```nim
let sql = "UPDATE users SET name='John' where id = 1"
RDB().raw(sql).exec()
```

## Aggregates
[to index](#index)

```nim
import allographer/query_builder

echo RDB().table("users").count()
>> 10       # int

echo RDB().table("users").max("name")
>> "user9"  # string

echo RDB().table("users").max("id")
>> "10"     # string

echo RDB().table("users").min("name")
>> "user1"  # string

echo RDB().table("users").min("id")
>> "1"      # string

echo RDB().table("users").avg("id")
>> 5.5      # float

echo RDB().table("users").sum("id")
>> 55.0     # float
```

## Transaction
[to index](#index)

```nim
transaction:
  var user= RDB().table("users").select("id").where("name", "=", "user3").first()
  var id = user["id"].getInt()
  echo id
  user = RDB().table("users").select("name", "email").find(id)
  echo user
```
If all code in transaction block success, `COMMIT` is run otherwise `ROLLBACK`
