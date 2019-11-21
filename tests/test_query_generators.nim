import unittest

import ../src/allographer/query_builder_pkg/grammars
include ../src/allographer/query_builder_pkg/generators

suite "generators":
  test "selectSql id":
    let t = RDB().table("test").select("id")
    check t.selectSql().sqlString == "SELECT id"

  test "selectSql id, name":
    let t = RDB().table("test").select("id", "name")
    check t.selectSql().sqlString == "SELECT id, name"

  test "selectSql *":
    let t = RDB().table("test").select()
    check t.selectSql().sqlString == "SELECT *"

  test "fromSql":
    let t = RDB().table("test")
    check t.fromSql().sqlString == " FROM test"

  # test "selectByIdSql":
  #   let t = RDB().find(2)
  #   check t.fromSql().sqlString == " WHERE id = 2"