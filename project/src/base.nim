import json, os, strutils, parsecfg
import db_sqlite, db_mysql, db_postgres


type DBObject*[T] = ref object
  connectionInfo*: JsonNode
  sqlite*: db_sqlite.DbConn
  mysql*: db_mysql.DbConn
  postgres*: db_postgres.DbConn
  connection: T
  query*: JsonNode
  sqlStringSeq*: seq[string]


# proc setConnection*(this: DBObject): DBObject =
#   # specify conf path
#   let workingDirPath = getCurrentDir()
#   var confPathArray = workingDirPath.split("/")
#   confPathArray.add(["conf", "db.ini"])
#   let confPath = confPathArray.join("/")
#   echo confPath

#   # load conf
#   let conf = loadConfig(confPath)
#   let driver = conf.getSectionValue("", "driver")
#   let conn = conf.getSectionValue("", "connection")
#   let user = conf.getSectionValue("", "user")
#   let password = conf.getSectionValue("", "password")
#   let database = conf.getSectionValue("", "database")
#   this.connectionInfo = %*{
#     "driver": driver,
#     "conn": conn,
#     "user": user,
#     "password": password,
#     "database": database
#   }
#   return this

# proc db*(this: DBObject, conn: proc): DBObject =
