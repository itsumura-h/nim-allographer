import json
import ../src/allographer/query_builder


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


echo RDB().table("users").select("id", "email").limit(5).get()
echo RDB().table("users").select("id", "email").limit(5).first()
echo RDB().table("users").find(4)
echo RDB().table("users").select("id", "email").limit(5).find(3)

echo ""

RDB().table("users").insert(%*{"name": "John", "email": "John@gmail.com"}).exec()
echo RDB().table("users").insert(%*{"name": "John", "email": "John@gmail.com"}).execID()

RDB().table("users").insert(
    [
        %*{"name": "John", "email": "John@gmail.com"},
        %*{"name": "Paul", "email": "Paul@gmail.com"}
    ]
)
.exec()
RDB().table("users").inserts(
    [
        %*{"name": "John", "email": "John@gmail.com"},
        %*{"name": "Paul", "password": "PaulPass"}
    ]
)
.exec()


RDB().table("users").where("id", "=", 2).update(%*{"name": "David"}).exec()
echo RDB().table("users").where("id", "=", 2).update(%*{"name": "David"}).execID()
echo RDB().table("users").select().where("name", "=", "David").get()

echo ""

RDB().table("users").where("name", "=", "David").delete().exec()
RDB().table("users").delete(3).exec()
