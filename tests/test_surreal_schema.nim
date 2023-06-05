discard """
  cmd: "nim c -d:reset -r $file"
"""

import std/unittest
import std/asyncdispatch
import std/json
import std/times
import std/options
import ../src/allographer/connection
import ../src/allographer/query_builder


let surreal = dbOpen(SurrealDb, "test", "test", "user", "pass", "http://surreal", 8000, 10, 30, true, false).waitFor()

suite("surreal schema"):
  test("raw define"):
    let define = """
REMOVE TABLE types;
DEFINE TABLE types SCHEMAFULL;
DEFINE FIELD index ON TABLE types TYPE int;
DEFINE INDEX types_index ON TABLE types COLUMNS index UNIQUE;
DEFINE FIELD bool ON TABLE types TYPE bool;
DEFINE FIELD datetime ON TABLE types TYPE datetime;
DEFINE FIELD decimal ON TABLE types TYPE decimal;
DEFINE FIELD float ON TABLE types TYPE float;
DEFINE FIELD int ON TABLE types TYPE int;
DEFINE FIELD number ON TABLE types TYPE number;
DEFINE FIELD object ON TABLE types TYPE object;
DEFINE FIELD string ON TABLE types TYPE string;
"""
    surreal.raw(define).exec().waitFor()
    echo surreal.raw("INFO FOR TABLE types").info().waitFor().pretty()

    for i in 1..5:
      let id = surreal.table("types").insertId(%*{
        "index": i,
        "bool": true,
        "datetime": $(now()),
        "decimal": 1.11,
        "float": 1.11,
        "int": "rand()",
        "number": "rand()",
        "object": """ {"key": "value"} """,
        "string": "aaa"
      }).waitFor()
      echo surreal.table("types").find(id).waitFor().get().pretty()
