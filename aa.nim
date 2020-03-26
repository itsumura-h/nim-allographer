import src/allographer/connection
# import db_postgres

type A = ref object
  db*: DbConn

let db = db()
let pmysql = PMySQL(db)
echo pmysql.repr
# let db = open("postgres:5432", "user", "Password!", "allographer")
# echo db.unsafeAddr().repr
echo A().db.repr
echo A(db:db).db.repr
echo A(db:db).db.repr == "nil\n"
echo A(db:db).db.repr.type
db.close()