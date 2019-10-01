import ../../src/allographer
import db_sqlite

proc conn*(): DbConn =
  open("/home/www/example/db.sqlite3", "", "", "")

export RDB, allographer
