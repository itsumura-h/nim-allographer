import os, strutils

const
  isExistsSqlite* = when existsEnv("sqlite"): getEnv("sqlite").parseBool else: false
  isExistsPostgres* = when existsEnv("postgres"): getEnv("postgres").parseBool else: false
  isExistsMysql* = when existsEnv("mysql"): getEnv("mysql").parseBool else: false
  isExistsMariadb* = when existsEnv("mariadb"): getEnv("mariadb").parseBool else: false
