discard """
  cmd: "nim c -d:reset -r $file"
"""

import std/unittest
import ../src/allographer/schema_builder
include ../src/allographer/schema_builder/queries/mysql/impl


suite("scema mysql generator"):
  test("serialGenerator"):
    check Column.increments("id").serialGenerator() ==
      "`id` BIGINT NOT NULL PRIMARY KEY AUTO_INCREMENT"

  test("nullable intGenerator"):
    check Column.integer("int").nullable().intGenerator() ==
      "`int` INT"

  test("intGenerator"):
    check Column.integer("int").intGenerator() ==
      "`int` INT NOT NULL"

  test("default"):
    check Column.integer("int").default(0).nullable().intGenerator() ==
      "`int` INT DEFAULT 0"

  test("unsigned"):
    check Column.integer("int").nullable().unsigned().intGenerator() ==
      "`int` INT UNSIGNED"
