import std/json
import ../log
import ./databases/database_types


type
  Driver* = enum
    MySQL
    MariaDB
    PostgreSQL
    SQLite3

  Rdb* = ref object
    driver*: Driver
    conn*: Connections
    log*: LogSetting
    query*: JsonNode
    sqlString*: string
    placeHolder*: seq[string]
    # for transaction
    isInTransaction*:bool
    transactionConn*:int

  RawQueryRdb* = ref object
    driver*: Driver
    conn*: Connections
    log*: LogSetting
    query*: JsonNode
    sqlString*: string
    placeHolder*: seq[string]
    # for transaction
    isInTransaction*:bool
    transactionConn*:int
