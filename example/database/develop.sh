nim c -d:reset --threads:off ./migrations/migrate.nim
nim c --threads:off ./seeder/develop

./migrations/migrate
./seeder/develop
