import db_sqlite

proc db*(): DbConn =
  open("/home/www/example/sqliteTest.sqlite3", "user", "Password!", "allographer")
