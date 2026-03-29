import json
import ../src/allographer/connection
import ../src/allographer/query_builder

let rdb = dbOpen(SQLite3, ":memory:", shouldDisplayLog=false)

discard rdb.table("world").where("id", "=", 1).update(%*{"randomnumber": 2})
discard rdb.table("World").where("Id", "=", 1).update(%*{"randomNumber": 2})
discard rdb.select("id", "randomnumber").table("world").where("id", "=", 1).get()
discard rdb.select("id", "randomNumber").table("World").where("Id", "=", 1).get()
