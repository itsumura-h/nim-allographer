import column

type Table* = ref object
  name*: string
  columns*: seq[Column]
  reset*: bool


proc table*(name:string, columns:openArray[Column], reset=false): Table =
  var table = Table(
    name: name,
    columns: @columns,
    reset: reset
  )

  return table
