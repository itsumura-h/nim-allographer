import unittest, json
include allographer


suite "table":
  test "table generate JsonNode":
    check table("users") == %*{"table": "users"}

suite "select":
  test "select empty arg":
    check table("users").select()["select"] == %*["*"]
  test "select with args":
    check table("users").select("id", "name")["select"] == %*["id", "name"]

suite "where":
  test "one where, arge string":
    check table("users").where("name", "=", "John")["where"] == %*[{"column": "name", "symbol": "=", "value": "John"}]
  test "one where, args int":
    check table("users").where("id", "=", 1)["where"] == %*[{"column": "id", "symbol": "=", "value": 1}]
  test "multi where":
    let query = table("users").where("name", "=", "John").where("id", "=", 1)
    check query["where"] == %*[
                                {"column": "name", "symbol": "=", "value": "John"},
                                {"column": "id", "symbol": "=", "value": 1}
                              ]

suite "orWhere":
  test "one orWhere":
    check table("users").orWhere("name", "=", "John")["or_where"] == %*[{"column": "name", "symbol": "=", "value": "John"}]

  test "multi orWhere strng":
    let query = table("users").orWhere("name", "=", "John").orWhere("name", "=", "Paul")
    check query["or_where"] == %*[
                                  {"column": "name", "symbol": "=", "value": "John"},
                                  {"column": "name", "symbol": "=", "value": "Paul"}
                                ]
  test "multi orWhere int":
    let query = table("users").orWhere("name", "=", "John").orWhere("id", "=", 1)
    check query["or_where"] == %*[
                                  {"column": "name", "symbol": "=", "value": "John"},
                                  {"column": "id", "symbol": "=", "value": 1}
                                ]

suite "join":
  test "one join":
    let query = table("users").join("auth", "user.auth_id", "=", "auth.id")
    check query["join"] == %*[{"table": "auth",
                              "column1": "user.auth_id",
                              "symbol": "=",
                              "column2": "auth.id"
                            }]

  test "multi join":
    let query = table("users")
                .join("auth", "user.auth_id", "=", "auth.id")
                .join("a", "user.a_id", "=", "a.id")
    
    check query["join"] == %*[
                            {"table": "auth",
                              "column1": "user.auth_id",
                              "symbol": "=",
                              "column2": "auth.id"
                            },
                            {"table": "a",
                              "column1": "user.a_id",
                              "symbol": "=",
                              "column2": "a.id"
                            }
                          ]

suite "offset":
  test "offset":
    check table("users").offset(3)["offset"].getInt() == 3

suite "limit":
  test "limit":
    check table("users").limit(3)["limit"].getInt() == 3