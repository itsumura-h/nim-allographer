import strformat, json, progress
import bcrypt

import ../src/allographer/query_builder
import ../src/allographer/schema_builder

schema([
  table("auth",[
    Column().increments("id"),
    Column().string("auth")
  ], reset=true),
  table("users",[
    Column().increments("id"),
    Column().string("name").nullable(),
    Column().string("email").nullable(),
    Column().string("password").nullable(),
    Column().string("salt").nullable(),
    Column().string("address").nullable(),
    Column().date("birth_date").nullable(),
    Column().foreign("auth_id").reference("id").on("auth").onDelete(SET_NULL)
  ], reset=true)
])

# シーダー
RDB().table("auth").insert([
  %*{"auth": "admin"},
  %*{"auth": "user"}
])

# プログレスバー
let total = 20
var pb = newProgressBar(total=total) # totalは分母

pb.start()
var insertData: seq[JsonNode]
for i in 1..total:
  let salt = genSalt(10)
  let password = hash(&"password{i}", salt)
  let authId = if i mod 2 == 0: 1 else: 2
  insertData.add(
    %*{
      "name": &"user{i}",
      "email": &"user{i}@gmail.com",
      "password": password,
      "salt": salt,
      "auth_id": authId
    }
  )
  pb.increment()
pb.finish()

RDB().table("users").insert(insertData)

discard RDB().table("users").get()

echo RDB()
    .table("users")
    .select("users.id", "users.email")
    .where("name", "=", "user3")
    .orWhere("name", "=", "user4")
    .orWhere("users.id", "=", 5)
    .join("auth", "auth.id", "=", "users.auth_id")
    .limit(10)
    .get()


echo RDB().table("users").select("id", "email").limit(5).get()
echo RDB().table("users").select("id", "email").limit(5).first()
echo RDB().table("users").find(4)
echo RDB().table("users").select("id", "email").limit(5).find(3)

echo ""

RDB().table("users").insert(%*{"name": "John", "email": "John@gmail.com"})
echo RDB().table("users").insertID(%*{"name": "John", "email": "John@gmail.com"})


RDB().table("users").insert(
  [
      %*{"name": "John", "email": "John@gmail.com"},
      %*{"name": "Paul", "email": "Paul@gmail.com"}
  ]
)

RDB().table("users").inserts(
  [
      %*{"name": "Mick", "email": "Mick@gmail.com"},
      %*{"name": "Keith", "password": "KeithPass"}
  ]
)


RDB().table("users").where("id", "=", 2).update(%*{"name": "David"})
RDB().table("users").where("id", "=", 2).update(%*{"name": "David"})
echo RDB().table("users").select().where("name", "=", "David").get()
echo RDB().table("users").find(2)

RDB().table("users").where("name", "=", "David").delete()
RDB().table("users").delete(3)
echo RDB().table("users").find(3)
echo RDB().table("users").limit(5).get()
echo RDB().table("users").select("name").where("address", "is", nil).get()

# # sql check
let r = RDB()
    .table("users")
    .select("users.id", "users.email")
    .where("name", "=", "user3")
    .where("name", "=", "user4")
    .where("users.id", "=", 5)
    .orWhere("name", "=", "user6")
    .orWhere("users.id", "=", 7)
    .join("auth", "auth.id", "=", "users.auth_id")
    .limit(10)
    .get()
echo r[0]["id"]
echo r[0]["id"].type
echo r[0]["email"]
echo r[0]["email"].type

type User = ref object
  id:int
  name:string
  email:string
  password:string
  salt:string
  address:string
  birth_date:string
  auth_id:int
let users = RDB().table("users").limit(5).get(User)
for user in users:
  echo user.name

alter(
  drop("users"),
  drop("auth")
)
