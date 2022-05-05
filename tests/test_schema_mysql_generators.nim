discard """
  cmd: "nim c -d:reset -r $file"
"""

import unittest
include ../src/allographer/schema_builder/queries/mysql/impl
import ../src/allographer/schema_builder

block:
  check Column.increments("id").serialGenerator() ==
    "`id` BIGINT NOT NULL PRIMARY KEY AUTO_INCREMENT"

block:
  check Column.integer("int").nullable().intGenerator() ==
    "`int` INT"

block:
  check Column.integer("int").intGenerator() ==
    "`int` INT NOT NULL"

block:
  check Column.integer("int").default(0).nullable().intGenerator() ==
    "`int` INT DEFAULT 0"

block:
  check Column.integer("int").nullable().unsigned().intGenerator() ==
    "`int` INT UNSIGNED"
