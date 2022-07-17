import
  std/os,
  std/strutils

const
  isExistsSqlite* = getEnv("DB_SQLITE", $false).parseBool
  isExistsPostgres* = getEnv("DB_POSTGRES", $false).parseBool
  isExistsMysql* = getEnv("DB_MYSQL", $false).parseBool
  isExistsMariadb* = getEnv("DB_MARIADB", $false).parseBool
