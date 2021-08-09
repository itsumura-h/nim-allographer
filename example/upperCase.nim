import json
import ../src/allographer/query_builder

discard Rdb().table("world").where("id", "=", 1).updateSql(%*{"randomnumber": 2})
discard Rdb().table("World").where("Id", "=", 1).updateSql(%*{"randomNumber": 2})
discard Rdb().table("world").select("id", "randomnumber").where("id", "=", 1).selectSql()
discard Rdb().table("World").select("id", "randomNumber").where("Id", "=", 1).selectSql()
