import db_sqlite

proc db*(): DbConn =
    open("localhost:5432", "user", "pass", "db")
