discard """
  cmd: "nim c -d:reset $file"
"""

import std/json
import std/unittest
import ../../src/allographer/query_builder/libs/surreal/surreal_lib


suite "SurrealDB lib helpers":
  test "numToAlphabet":
    check numToAlphabet(1) == "a"
    check numToAlphabet(26) == "z"
    check numToAlphabet(27) == "aa"

  test "questionToDaller":
    check questionToDaller("SELECT * FROM user WHERE name = ? AND age = ?") ==
      "SELECT * FROM user WHERE name = $a AND age = $b"

  test "dbFormat json args":
    let sql = dbFormat(
      "SELECT * FROM user WHERE name = ? AND age = ?",
      %*["alice", 42]
    )
    check sql ==
      "LET $a = \"alice\"; LET $b = 42; SELECT * FROM user WHERE name = $a AND age = $b"
