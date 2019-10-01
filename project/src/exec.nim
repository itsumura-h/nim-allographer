import db_sqlite, db_mysql, db_postgres
import base
import json, os, strformat, strutils, parsecfg

## ==================== connection ====================
proc sqlite_connection*(conn: string): db_sqlite.DbConn =
  echo conn
  let connection = db_sqlite.open(conn, "", "", "")
  return connection

proc mysql_connection*(conn: string,
                      user: string,
                      password: string,
                      database: string): db_mysql.DbConn =
  let connection = db_mysql.open(conn, user, password, database)
  return connection

proc postgres_connection*(conn: string,
                          user: string,
                          password: string,
                          database: string): db_postgres.DbConn =
  let connection = db_postgres.open(conn, user, password, database)
  return connection


proc setConnection*(this: DBObject): DBObject =
  let workingDirPath = getCurrentDir()
  var confPathArray = workingDirPath.split("/")
  confPathArray.add(["conf", "db.ini"])
  let confPath = confPathArray.join("/")
  echo confPath

  # load conf
  let conf = loadConfig(confPath)
  let driver = conf.getSectionValue("", "driver")
  let conn = conf.getSectionValue("", "connection")
  let user = conf.getSectionValue("", "user")
  let password = conf.getSectionValue("", "password")
  let database = conf.getSectionValue("", "database")
  this.connectionInfo = %*{
    "driver": driver,
    "conn": conn,
    "user": user,
    "password": password,
    "database": database
  }

  # set connection
  echo driver
  if driver == "sqlite":
    this.connection = sqlite_connection(conn)
  if driver ==  "mysql":
    this.connection = mysql_connection(conn, user, password, database)
  # of "postgres":
  #   this.postgres = postgres_connection(conn, user, password, database)
  
  echo repr this
  return this
  

proc get*(thisArg: DBObject): seq =
  let this = thisArg.connection()
  this.sqlite.close()

  # let table = this.query["table"].getStr()
  # var sqlString = &"SELECT * FROM {table}"
  # if this.connectionInfo["driver"].getStr() == "sqlite":
  #   return this.sqlite.getAllRows(sql sqlString)
  return @[""]
  

## ==================================================
## exec
## ==================================================

proc exec*(this: DBObject) =
  let sqlStringSeq = this.sqlStringSeq
  echo sqlStringSeq

  # let db = this.connection()
  # for sqlString in sqlStringSeq:
  #   echo sqlString
  #   db.exec(sql sqlStringArg)

  # db.close()

