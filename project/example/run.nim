import conf/database
import json
import db_sqlite, db_mysql, db_postgres

import ../src/base
import ../src/exec

echo RDB().table("auth").get(conn)