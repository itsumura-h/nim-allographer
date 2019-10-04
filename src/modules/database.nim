import db_sqlite

proc db*(): DbConn =
  open("/home/www/test.sqlite3", "", "", "")
