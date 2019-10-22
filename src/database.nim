import db_mysql

proc db*(): DbConn =
  open("mysql:3306", "user", "Password", "allographer")
