import db_sqlite

proc db*(): DbConn =
  open("/home/www/db.sqlite3", "user", "Password!", "allographer")

const DRIVER = "sqlite"
proc getDriver*():string =
  return DRIVER


const CONSOLE_LOG = true
proc getConsoleLog*():bool =
  return CONSOLE_LOG

const FILE_LOG = true
proc getFileLog*():bool =
  return FILE_LOG

const LOG_DIR = "/home/www/logs"
proc getLogDir*():string =
  return LOG_DIR