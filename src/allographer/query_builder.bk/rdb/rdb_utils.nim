import std/strformat
import std/strutils
import ./rdb_types


proc liteQuoteSchema*(input:var string) =
  input = &"`{input}`"

proc myQuoteSchema*(input:var string) =
  input = &"`{input}`"

proc pgQuoteSchema*(input:var string) =
  input = &"\"{input}\""

proc quoteSchema*(input:var string, driver:Driver) =
  var isUpper = false
  for c in input:
    if c.isUpperAscii():
      isUpper = true
      break
  if isUpper:
    case driver:
    of SQLite3:
      liteQuoteSchema(input)
    of MySQL, MariaDB:
      myQuoteSchema(input)
    of PostgreSQL:
      pgQuoteSchema(input)


proc liteQuoteColumn*(input:var string) =
  var tmp = newSeq[string]()
  for row in input.split("."):
    if row.contains(" as "):
      let c = row.split(" as ")
      tmp.add(&"`{c[0]}` as `{c[1]}`")
    else:
      tmp.add(&"`{row}`")
  input = tmp.join(".")

proc myQuoteColumn*(input:var string) =
  var tmp = newSeq[string]()
  for row in input.split("."):
    if row.contains(" as "):
      let c = row.split(" as ")
      tmp.add(&"`{c[0]}` as `{c[1]}`")
    else:
      tmp.add(&"`{row}`")
  input = tmp.join(".")

proc pgQuoteColumn*(input:var string) =
  var tmp = newSeq[string]()
  for row in input.split("."):
    if row.contains(" as "):
      let c = row.split(" as ")
      tmp.add(&"\"{c[0]}\" as \"{c[1]}\"")
    else:
      tmp.add(&"\"{row}\"")
  if tmp.len > 1:
    input = tmp.join(".")
  else:
    input = tmp[0]

proc quote*(input:var string, driver:Driver) =
  case driver:
  of SQLite3:
    liteQuoteColumn(input)
  of MySQL, MariaDB:
    myQuoteColumn(input)
  of PostgreSQL:
    pgQuoteColumn(input)
