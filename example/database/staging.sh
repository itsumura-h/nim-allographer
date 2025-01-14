nim c -d:reset ./migrations/migrate.nim
nim c database/seeder/staging

./migrations/migrate
APP_ENV=staging ./database/seeder/staging
