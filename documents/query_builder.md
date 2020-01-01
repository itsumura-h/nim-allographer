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

- [INSERT](#INSERT)
- [UPDATE](#UPDATE)
- [DELETE](#DELETE)
- [RAW_SQL](#RAW_SQL)
- [Aggregates](#Aggregates)

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

### Examples

#### get
Retrieving all row from a table
```nim
let users = RDB().table("users").get()
for user in users:
  echo user["name"]
```

#### first
Retrieving a single row from a table
```nim
let user = RDB()
            .table("users")
            .where("name", "=", "John")
            .first()
echo user["name"]
```

#### find
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

#### join
```nim
let users = RDB()
            .table("users")
            .select("users.id", "contacts.phone", "orders.price")
            .join("contacts", "users.id", "=", "contacts.user_id")
            .join("orders", "users.id", "=", "orders.user_id")
            .get()
```

#### where
```nim
let users = RDB().table("users").where("age", ">", 25).get()
```
#### orWhere
```nim
let users = RDB()
            .table("users")
            .where("age", ">", 25)
            .orWhere("name", "=", "John")
            .get()
```

#### whereBetween
```nim
let users = RDB()
            .table("users")
            .whereBetween("age", [25, 35])
            .get()
```

#### whereNotBetween
```nim
let users = RDB()
            .table("users")
            .whereNotBetween("age", [25, 35])
            .get()
```

#### whereIn
```nim
let users = RDB()
            .table("users")
            .whereIn("id", @[1, 2, 3])
            .get()
```

#### whereNotIn
```nim
let users = RDB()
            .table("users")
            .whereNotIn("id", @[1, 2, 3])
            .get()
```

#### whereNull
```nim
let users = RDB()
            .table("users")
            .whereNull("updated_at")
            .get()
```

#### groupBy_having
```nim
let users = RDB()
            .table("users")
            .group_by("count")
            .having("count", ">", 100)
            .get()
```

#### orderBy
```nim
let users = RDB()
            .table("users")
            .orderBy("name", Desc)
            .get()
```
2nd arg of `orderBy` is Enum. `Desc` or `Asc`


#### limit_offset
```nim
let users = RDB()
            .table("users")
            .offset(10)
            .limit(5)
            .get()
```

#### paginate
```nim
RDB().table("users").delete(2)
let users = User
            .select("id", "name")
            .table("users")
            .paginate(3, 1)
```
arg1... Numer of items per page  
arg2... Numer of page(option)(1 is set by default)

```
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