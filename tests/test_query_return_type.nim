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


template orm(head, body: untyped) =
  echo head
  echo body
  "a"

  # var response: seq[body.type]
  # for row in head:
  #   body.id = row["id"].getInt()
  #   body.name = row["name"].getStr()
  #   body.birth_date = row["birth_date"].getStr().parse("yyyy-MM-dd")
  #   response.add(typ)
  # response


var typ: tuple[id:int, name:string, birth_date:DateTime]
var response = RDB().table("users").get().orm(typ)
echo response