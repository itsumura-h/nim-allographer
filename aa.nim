import src/allographer/query_builder/base
import src/allographer/connection

let db = db()
var rdb = RDB(db:db, isInTransaction:true)
echo rdb.isInTransaction

rdb = RDB()
echo rdb.isInTransaction