import db_sqlite

proc db*(): DbConn =
  open("localhost:3306", "user", "pass", "db")
