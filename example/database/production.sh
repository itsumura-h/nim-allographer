nim c --threads:off ./migrations/migrate.nim
nim c --threads:off database/seeder/production

./migrations/migrate
APP_ENV=production ./database/seeder/production
