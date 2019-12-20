import db_sqlite

proc db*(): DbConn =
  open("/home/www/example/db.sqlite3", "", "", "")

const DRIVER* = "sqlite"
