import db_sqlite

proc db*(): DbConn =
  open("/home/www/db.sqlite3", "", "", "")
  # open(":memory:", "", "", "")
