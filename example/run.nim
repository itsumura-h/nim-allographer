import ../src/allographer
# import allographer
import json
import db_sqlite


# echo RDB().table("users").get(conn)

echo RDB()
    .table("users")
    .select("id", "email")
    .where("name", "=", "John")
    .where("id", "=", 3)
    .orWhere("name", "=", "George")
    .orWhere("id", "=", 4)
    .join("auth", "auth.id", "=", "auth_id")
    .join("auth", "auth.id", "=", "auth_id")
    .limit(10)
    .offset(5)
    .sqlString


echo RDB().table("users").select("id", "email").limit(5).get(db)
echo RDB().table("users").select("id", "email").limit(5).first(db)
echo RDB().table("users").find(4, db)
echo RDB().table("users").select("id", "email").limit(5).find(3, db)

echo ""

RDB().table("users").insert(%*{"name": "John", "email": "John@gmail.com"}).exec(db)
echo RDB().table("users").insert(%*{"name": "John", "email": "John@gmail.com"}).execID(db)

RDB().table("users").insert(
    [
        %*{"name": "John", "email": "John@gmail.com"},
        %*{"name": "Paul", "email": "Paul@gmail.com"}
    ]
)
.exec(db)
RDB().table("users").inserts(
    [
        %*{"name": "John", "email": "John@gmail.com"},
        %*{"name": "Paul", "password": "PaulPass"}
    ]
)
.exec(db)


RDB().table("users").where("id", "=", 2).update(%*{"name": "David"}).exec(db)
echo RDB().table("users").where("id", "=", 2).update(%*{"name": "David"}).execID(db)
echo RDB().table("users").select().where("name", "=", "David").get(db)

echo ""

RDB().table("users").where("name", "=", "David").delete().exec(db)
RDB().table("users").delete(3).exec(db)
