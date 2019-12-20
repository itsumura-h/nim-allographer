import db_sqlite
export db_sqlite.dbQuote

proc db*(): DbConn =
  open("/home/www/db.sqlite3", "user", "Password!", "allographer")

const DRIVER* = "sqlite"
