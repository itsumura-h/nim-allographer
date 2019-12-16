import unittest

include ../src/allographer/schema_builder/table

suite "schema table":
  test "table":
    var c = Column()
    var t = Table().create("users", [c], reset=true)
    check t.name == "users"
    check t.columns == @[c]
    check t.reset == true
