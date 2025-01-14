nim c -d:reset ./migrations/migrate.nim
nim c ./seeder/develop

./migrations/migrate
./seeder/develop
