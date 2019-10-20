import db_sqlite
import os, strformat, json
import bcrypt
import ../src/allographer

# ファイル削除
let rdb = db()
try:
  rdb.exec(sql"drop table auth")
  rdb.exec(sql"drop table users")
except Exception:
  echo getCurrentExceptionMsg()

# マイグレーション
rdb.exec(
  sql"""
  CREATE TABLE auth(
    id INTEGER PRIMARY KEY,
    auth VARCHAR
  )"""
)

rdb.exec(
  sql"""
  CREATE TABLE users(
    id INTEGER PRIMARY KEY,
    name VARCHAR,
    email VARCHAR,
    password VARCHAR,
    salt VARCHAR,
    address VARCHAR,
    birth_date DATE,
    auth_id INT
  )"""
)
rdb.close()

RDB().table("auth").insert([
  %*{"auth": "admin"},
  %*{"auth": "user"}
])
.exec(db)


var insertData: seq[JsonNode]
for i in 1..100:
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
RDB().table("users").insert(insertData).exec(db)
