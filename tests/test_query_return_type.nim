import times, strformat, json

import ../src/allographer/query_builder
import ../src/allographer/schema_builder

Schema().create(
  Table().create("users", [
    Column().increments("id"),
    COlumn().string("name").nullable(),
    Column().date("birth_date").nullable()
  ], reset=true)
)

var users: seq[JsonNode]
for i in 1..5:
  users.add(
    %*{
      "name": &"user{i}",
      "birth_date": &"1990-01-0{i}"
    }
  )

RDB().table("users").insert(users).exec()

type Type = ref object of ResponseType
  id: int
  name: string
  birth_date: DateTime
var typ = Type()
# echo RDB().table("users").get(Typ)

proc orm(response:JsonNode): seq[Type] =
  

RDB().table("users").getWithType(typ)