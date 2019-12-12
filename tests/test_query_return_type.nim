from macros import parseStmt
import times, strformat, json, strutils

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


proc orm(response_arg:seq[seq[string]], typ:var tuple, responseName:string) =
  var response: seq[typ.type]
  for row in response_arg:
    var i = 0
    for typRow in typ.fields:
      # echo "-----------------------"
      # echo row[i]
      # echo repr typRow
      # echo typRow.type
      var typPtr = typRow.addr
      echo repr typPtr
      var column = row[i]
      if typRow.type is int:
        typ.id = column.parseInt
      elif typRow.type is "".type:
        typ.name = column
      elif typRow.type is DateTime:
        typ.birth_date = column.parse("yyyy-MM-dd")
      i.inc()
    response.add(typ)
  echo response
  

var typ: tuple[id:int, name:string, birth_date:DateTime]
# var RDB().table("users").get().orm(typ, "response")
RDB().table("users").getString().orm(typ, "response")
# echo response

#[

macro orm(response_arg, typ, responseName: untyped): untyped =
  var strBody = fmt"""
var {responseName}: seq[{repr typ}.type]
for i, row in {repr response_arg}.pairs:
  {repr typ}.id = row["id"].getInt()
  {repr typ}.name = row["name"].getStr()
  {repr typ}.birth_date = row["birth_date"].getStr().parse("yyyy-MM-dd")
  {responseName}.add(typ)"""

  result = parseStmt(strBody)



var response: seq[body.type]
for row in head:
  body.id = row["id"].getInt()
  body.name = row["name"].getStr()
  body.birth_date = row["birth_date"].getStr().parse("yyyy-MM-dd")
  response.add(typ)
response

]#
