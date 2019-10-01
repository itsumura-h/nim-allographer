import ../../src/allographer
import db_sqlite
import os, strutils

proc connection*(this: DBObject): DbConn =
  let workingDirPath = getCurrentDir()
  var confPathArray = workingDirPath.split("/")
  confPathArray.delete(confPathArray.len - 1)

  let conn = open("/home/db/db.sqlite3", "", "", "")
  return conn

export DBObject, allographer
