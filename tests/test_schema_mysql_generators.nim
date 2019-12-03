import unittest
include ../src/allographer/schema_builder_pkg/generators/mysql_generators

suite "mysql generators int":
  test "serialGenerator":
    check serialGenerator("id") == "'id' INT PRIMARY KEY"

  test "intGenerator":
    check intGenerator("int", true, false, 0, false) == "'int' INT"
  
  test "intGenerator not null":
    check intGenerator("int", false, false, 0, false) == "'int' INT NOT NULL"
  
  test "intGenerator default":
    check intGenerator("int", true, true, 0, false) == "'int' INT DEFAULT 0"
  
  test "intGenerator unsigned":
    check intGenerator("int", true, false, 0, true) == "'int' INT UNSIGNED"