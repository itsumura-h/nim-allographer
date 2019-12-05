import db_postgres

proc db*(): DbConn =
  open("postgres:5432", "user", "Password!", "allographer")

const DRIVER* = "postgres"
