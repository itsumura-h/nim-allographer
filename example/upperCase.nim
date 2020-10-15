import json
import ../src/allographer/query_builder

discard RDB().table("world").where("id", "=", 1).updateSql(%*{"randomnumber": 2})
discard RDB().table("World").where("Id", "=", 1).updateSql(%*{"randomNumber": 2})
discard RDB().table("world").select("id", "randomnumber").where("id", "=", 1).selectSql()
discard RDB().table("World").select("id", "randomNumber").where("Id", "=", 1).selectSql()
