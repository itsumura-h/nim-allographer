import std/strutils
import std/sequtils


proc snakeToCamel*(s: string): string =
  ## convert snake_case to CamelCase
  result = s.split("_").mapIt(it.capitalizeAscii()).join("")
