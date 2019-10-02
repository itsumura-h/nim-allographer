import conf/database
import json
import db_sqlite, db_mysql, db_postgres


# echo RDB().table("users").get(conn)

# echo RDB()
#     .table("users")
#     .select("id", "email")
#     .where("name", "=", "John")
#     .where("id", "=", 3)
#     .orWhere("name", "=", "George")
#     .orWhere("id", "=", 4)
#     .join("auth", "auth.id", "=", "auth_id")
#     .join("auth", "auth.id", "=", "auth_id")
#     .limit(10)
#     .offset(5)
#     .selectSql()
#     .fromSql()
#     .joinSql()
#     .whereSql()
#     .orWhereSql()
#     .limitSql()
#     .offsetSql()
#     .sqlString


echo RDB().table("users").select("id", "email").limit(5).get(db)
echo RDB().table("users").select("id", "email").limit(5).first(db)
echo RDB().table("users").find(4, db)
echo RDB().table("users").select("id", "email").limit(5).find(3, db)