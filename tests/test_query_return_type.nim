import macros, times, strformat, json, strutils, re, options

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


proc ormProc(response_arg:seq[seq[string]], typ:var tuple, responseName:string) =
  var response: seq[typ.type]
  var responseRaw = newNimNode(nnkTupleTy)
  echo repr responseRaw
  for row in response_arg:
    for typRow in typ.fields:
      echo "-----------------------"
      # echo row[i]
      echo typRow
      echo typRow.type
    response.add(typ)
  echo response


macro ormMacro(response_arg, typ, responseName:typed):untyped =
  echo typ.getTypeInst.repr.type
  var typKeys: seq[string]
  for m in typ.getTypeInst.repr.split({'[', ' ', ']'}):
    if m.contains(":"):
      var typKey = m.split(":")[0] 
      typKeys.add(typKey)
  echo typKeys

  var i = 0
  result = parseStmt(fmt"""
for i, row in {response_arg.repr}:
  echo {i.repr}, "   ", i, "   ", row

""")


#   var strBody = fmt"""
# var {responseName}: seq[{repr typ}.type]
# for i, typKey in {typKeys}.pairs:
#   echo i, "  ", typKey
#   if {repr typ}[i].type == int:
#     {repr typ}.{typKey} = row[i].parseInt()
#   elif {repr typ}[i].tpye == "".type:
#     {repr typ}.{typKey} = row[i]
#   elif {repr typ}[i].tpye == Datetime:
#     {repr typ}.{typKey} = row[i].parse("yyyy-MM-dd")
# {responseName}.add(typ)"""

#   result = parseStmt(strBody)


var typ: tuple[id:int, name:string, birth_date:DateTime]
# RDB().table("users").getString().ormProc(typ, "response")
RDB().table("users").getString().ormMacro(typ, "response")
# echo response


#[

if {repr typ}[i].type == int:
  {repr typ}.{typKey} = row[i].parseInt()
elif {repr typ}[i].tpye == "".type:
  {repr typ}.{typKey} = row[i]
elif {repr typ}[i].tpye == Datetime:
  {repr typ}.{typKey} = row[i].parse("yyyy-MM-dd")

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
