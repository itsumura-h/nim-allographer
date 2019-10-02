import ../../src/allographer
import db_sqlite

proc db*(): DbConn =
  return open("/home/www/example/db.sqlite3", "", "", "")

export RDB, allographer
