import column

type
  TableTyp* = enum
    Nomal
    Rename
    Drop

  Table* = ref object
    name*: string
    columns*: seq[Column]
    reset*: bool
    alterTo*:string
    # alter table
    typ*:TableTyp


proc table*(name:string, columns:openArray[Column], reset=false):Table =
  return Table(
    name: name,
    columns: @columns,
    reset: reset
  )
