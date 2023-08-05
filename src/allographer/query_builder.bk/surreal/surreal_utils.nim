import std/strformat
import std/strutils


proc quoteTable*(input:var string) =
  input = &"`{input}`"

proc quoteColumn*(input:var string) =
  var tmp = newSeq[string]()
  for row in input.split("."):
    if row.contains(" as "):
      let c = row.split(" as ")
      tmp.add(&"`{c[0]}` as `{c[1]}`")
    else:
      tmp.add(&"`{row}`")
  input = tmp.join(".")
