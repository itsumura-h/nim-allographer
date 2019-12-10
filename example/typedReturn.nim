import times, json, typeinfo, macros

# type Type = ref object
#   id: int
#   name: string
#   birth_date: DateTime

# let response = Type(id:1, name:"John", birth_date: "1990-01-01".parse("yyyy-MM-dd"))
var typ: tuple[id:int, name:string, birth_date:DateTime]
var response = @[
                  %*{"id": 1, "name":"user1", "birth_date":"1990-01-01"},
                  %*{"id": 2, "name":"user2", "birth_date":"1990-01-02"}
                ]

macro orm(head, body: untyped) =
  echo head
  echo body

orm typ:
 response
# for v in typ.fields:
#   echo v

#[

proc orm(response_arg:openArray[JsonNode], typ:var tuple):seq[typ.type] =
  var response: seq[typ.type]
  for row in response_arg:
    typ.id = row["id"].getInt()
    typ.name = row["name"].getStr()
    typ.birth_date = row["birth_date"].getStr().parse("yyyy-MM-dd")
    response.add(typ)
  return response

]#