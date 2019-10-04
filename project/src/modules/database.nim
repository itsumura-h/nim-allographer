import db_sqlite

proc db*(): DbConn =
  open("/home/www/project/example/db.sqlite3", "", "", "")
