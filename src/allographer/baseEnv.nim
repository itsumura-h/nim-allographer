import os, strutils

const
  isExistsSqlite* = when existsEnv("DB_SQLITE"): getEnv("DB_SQLITE").parseBool else: false
  isExistsPostgres* = when existsEnv("DB_POSTGRES"): getEnv("DB_POSTGRES").parseBool else: false
  isExistsMysql* = when existsEnv("DB_MYSQL"): getEnv("DB_MYSQL").parseBool else: false
  isExistsMariadb* = when existsEnv("DB_MARIADB"): getEnv("DB_MARIADB").parseBool else: false
