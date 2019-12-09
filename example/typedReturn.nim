import times

type Type = ref object
  id: int
  name: string
  birth_date: DateTime

let response = Type(id:1, name:"John", birth_date: "1990-01-01".parse("yyyy-MM-dd"))
echo repr response

echo response.id
echo response.id.type

echo response.name
echo response.name.type

echo response.birth_date
echo response.birth_date.type

response.id = 2
echo repr response

let columnName = "name"

# echo response.getter(columnName)
