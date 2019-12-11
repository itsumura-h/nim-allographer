from macros import parseStmt
import times, strformat, json

import ../src/allographer/query_builder
import ../src/allographer/schema_builder

Schema().create(
  Table().create("users", [
    Column().increments("id"),
    COlumn().string("name").nullable(),
    Column().date("birth_date").nullable(),
    Column().string("null").nullable()
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


macro orm(head, body: untyped): untyped =
  var strBody = ""
  strBody.add(fmt"""
proc toTuple(response_arg:openarray[JsonNode], typ:tuple):seq[]
  var response: seq[typ.type]
  for row in response_arg:
    typ.id = row["id"].getInt()
    typ.name = row["name"].getStr()
    typ.birth_date = row["birth_date"].getStr().parse("yyyy-MM-dd")
    response.add(typ)
  return response

return toTuple({repr head}, {repr body})""")
  result = parseStmt(strBody)


  # var response: seq[body.type]
  # for row in head:
  #   body.id = row["id"].getInt()
  #   body.name = row["name"].getStr()
  #   body.birth_date = row["birth_date"].getStr().parse("yyyy-MM-dd")
  #   response.add(typ)
  # response


var typ: tuple[id:int, name:string, birth_date:DateTime]
RDB().table("users").get().orm(typ)
# var response = RDB().table("users").get().orm(typ)
# echo response
# echo response[0]["id"]