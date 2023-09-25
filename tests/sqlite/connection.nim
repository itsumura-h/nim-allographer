import std/os
import std/strutils
import ../../src/allographer/connection

let maxConnections = getEnv("DB_MAX_CONNECTION").parseInt

let sqlite* = dbOpen(SQLite3, ":memory:", maxConnections=maxConnections, shouldDisplayLog=false)
# let sqlite* = dbopen(SQLite3, getCurrentDir() / "db.sqlite3" , maxConnections=maxConnections, shouldDisplayLog=true)
