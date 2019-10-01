import ../../src/allographer
import db_sqlite

proc connection*(this: DBObject): DbConn =
    let conn = open("/home/db/db.sqlite3", "", "", "")
    return conn

export DBObject, allographer
