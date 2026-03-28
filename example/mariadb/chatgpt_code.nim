import std/json
import ../../src/allographer/connection
import ../../src/allographer/query_builder

let rdb = dbOpen(MariaDB, "database", "user", "pass", "mariadb", 3306, shouldDisplayLog=true)

discard rdb.table("test").where("id", "=", 1).update(%*{"name": "alice"})
