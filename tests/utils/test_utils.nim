discard """
  cmd: "nim c -d:reset $file"
"""
# nim c -r tests/utils/test_utils.nim


import std/unittest
import ../../src/allographer/utils/snake_to_camel


suite("test utils"):
  test("snakeToCamel"):
    check snakeToCamel("test") == "Test"
    check snakeToCamel("test_case") == "TestCase"
    check snakeToCamel("test_case_abc") == "TestCaseAbc"
    check snakeToCamel("test_case_1") == "TestCase1"
