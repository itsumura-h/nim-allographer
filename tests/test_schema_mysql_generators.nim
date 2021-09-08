discard """
  cmd: "nim c -d:reset -r $file"
"""

import unittest
include ../src/allographer/schema_builder/generators/mysql_generators

block:
  check serialGenerator("id") == "`id` BIGINT NOT NULL PRIMARY KEY AUTO_INCREMENT"

block:
  check intGenerator("int", true, false, false, false, 0) == "`int` INT"

block:
  check intGenerator("int", false, false, false, false, 0) == "`int` INT NOT NULL"

block:
  check intGenerator("int", true, false, false, true, 0) == "`int` INT DEFAULT 0"

block:
  check intGenerator("int", true, false, true, false, 0) == "`int` INT UNSIGNED"