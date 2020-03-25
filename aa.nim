import db_postgres

type A = ref object
  db: DbConn

echo A().db.repr
echo A().db.repr == "nil\n"
echo A().db.repr.type