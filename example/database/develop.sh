nim c -d:reset ./migrations/migrate.nim
# nim c database/seeder/develop

./migrations/migrate
# APP_ENV=develop ./database/seeder/develop
