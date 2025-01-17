nim c -d:reset --threads:off./migrations/migrate.nim
nim c --threads:off database/seeder/staging

./migrations/migrate
APP_ENV=staging ./database/seeder/staging
