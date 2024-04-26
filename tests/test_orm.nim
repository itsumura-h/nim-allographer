discard """
  cmd: "nim c -d:reset -r $file"
"""

import std/unittest
import std/asyncdispatch
import std/json
import std/options
import ../src/allographer/query_builder

suite("test orm"):
  test("seq[JsonNode]"):
    type Typ = object
      bool: bool
      int: int
      float: float
      str: string

    proc function():Future[seq[JsonNode]] {.async.} =
      return @[
        %*{"bool":true, "int":1, "float": 1.1, "str": "str"},
        %*{"bool":false, "int":2, "float": 1.2, "str": "str"}
      ]

    let expect = @[
      Typ(bool: true, int: 1, float: 1.1, str: "str"),
      Typ(bool: false, int: 2, float: 1.2, str: "str")
    ]

    check function().orm(Typ).waitFor() == expect


  test("seq[JsonNode] empty"):
    type Typ = object
      bool: bool
      int: int
      float: float
      str: string

    proc function():Future[seq[JsonNode]] {.async.} =
      return @[]

    let expect:seq[Typ] = @[]

    check function().orm(Typ).waitFor() == expect


  test("Option[JsonNode] some"):
    type Typ = object
      bool: bool
      int: int
      float: float
      str: string

    proc function():Future[Option[JsonNode]] {.async.} =
      let json = %*{"bool":true, "int":1, "float": 1.1, "str": "str"}
      return json.some()

    let expect = Typ(bool: true, int: 1, float: 1.1, str: "str").some()

    check function().orm(Typ).waitFor() == expect


  test("Option[JsonNode] none"):
    type Typ = object
      bool: bool
      int: int
      float: float
      str: string

    proc function():Future[Option[JsonNode]] {.async.} =
      return none(JsonNode)

    let expect = none(Typ)
  
    check function().orm(Typ).waitFor() == expect
