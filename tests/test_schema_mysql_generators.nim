import unittest
include ../src/allographer/schema_builder/generators/mysql_generators

suite "mysql generators int":
  test "serialGenerator":
    check serialGenerator("id") == "`id` BIGINT NOT NULL PRIMARY KEY AUTO_INCREMENT"

  test "intGenerator":
    check intGenerator("int", true, false, false, false, 0) == "`int` INT"

  test "intGenerator not null":
    check intGenerator("int", false, false, false, false, 0) == "`int` INT NOT NULL"

  test "intGenerator default":
    check intGenerator("int", true, false, false, true, 0) == "`int` INT DEFAULT 0"

  test "intGenerator unsigned":
    check intGenerator("int", true, false, true, false, 0) == "`int` INT UNSIGNED"