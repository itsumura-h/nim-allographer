import db_sqlite
import os, strformat
import bcrypt

# ファイル削除
os.removeFile("db.sqlite3")

let db = open("db.sqlite3", "", "", "")

# マイグレーション
db.exec(
  sql"""
  CREATE TABLE auth(
    id INTEGER PRIMARY KEY,
    auth varchar
  )"""
)

db.exec(
  sql"""
  CREATE TABLE users(
    id INTEGER PRIMARY KEY,
    name varchar,
    email vachar,
    password varchar,
    auth_id INT
  )"""
)


db.exec(
  sql "INSERT INTO auth (id, auth) VALUES (1, \"admin\"), (2, \"user\")"
)

for i in 1..100:
  let salt = genSalt(10)
  let password = hash(&"password{i}", salt)
  let authId = if i mod 2 == 0: 1 else: 2
  db.exec(
    sql(&"INSERT INTO users (id, name, email, password, auth_id) VALUES ({i}, \"user{i}\", \"user{i}@gmail.com\", {password}, {auth_id})")
  )