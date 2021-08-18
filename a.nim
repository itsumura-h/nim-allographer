import db_mysql

let db = open("mariadb", "user", "Password!", "allographer")
db.exec(sql("""CREATE TABLE users (
                 id integer,
                 name varchar(50) not null)"""))
db.exec(sql"insert into users (name) values (?), (?), (?)", "user1","user2","user3",)
for row in db.fastRows(sql"select * from users"):
  echo row