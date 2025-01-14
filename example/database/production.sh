nim c ./migrations/migrate.nim
nim c database/seeder/production

./migrations/migrate
APP_ENV=production ./database/seeder/production
