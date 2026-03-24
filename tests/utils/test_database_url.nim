discard """
  cmd: "nim c -d:reset $file"
"""

import std/unittest
import ../../src/allographer/query_builder/libs/database_url


suite("database url"):
  test("parse query and credentials"):
    let url = parseDatabaseUrl(
      "postgresql://user%40mail:pa%3Ass@host:5432/db%2Fname?sslmode=require&application_name=allographer"
    )

    check url.scheme == "postgresql"
    check url.username == "user@mail"
    check url.password == "pa:ss"
    check url.hostname == "host"
    check url.hasPort
    check url.port == 5432
    check url.databaseName == "db/name"
    check url.query == @[
      (key: "sslmode", value: "require"),
      (key: "application_name", value: "allographer"),
    ]


  test("postgres alias stays valid"):
    let url = parseDatabaseUrl("postgres://user:pass@host:5432/database")
    check url.scheme == "postgres"


  test("port defaults are explicit"):
    let url = parseDatabaseUrl("mysql://user:pass@host/database")
    check not url.hasPort
    check portOrDefault(url, 3306) == 3306


  test("sqlite path from url"):
    let url = parseDatabaseUrl("sqlite://./relative/path.db")
    check sqliteDatabasePath(url) == "./relative/path.db"
    check sqliteDatabasePath(parseDatabaseUrl("sqlite://relative/path.db")) == "relative/path.db"
