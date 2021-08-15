# import os, strutils
# import dotenv

# for f in walkDir(getCurrentDir()):
#   if f.path.contains(".env"):
#     let env = initDotEnv(getCurrentDir(), f.path.split("/")[^1])
#     env.load()
#     echo("used config file '", f.path, "'")

# const
#   DRIVER* = getEnv("DB_DRIVER","sqlite").string

# let
#   CONN* = getEnv("DB_CONNECTION", getCurrentDir() / "db.sqlite3").string
#   USER* = getEnv("DB_USER", "").string
#   PASSWORD* = getEnv("DB_PASSWORD", "").string
#   DATABASE* = getEnv("DB_DATABASE", "").string
#   MAX_CONNECTION* = getEnv("DB_MAX_CONNECTION", "1").parseInt
#   IS_DISPLAY* = if existsEnv("LOG_IS_DISPLAY"): getEnv("LOG_IS_DISPLAY").string.parseBool else: false
#   IS_FILE* = if existsEnv("LOG_IS_FILE"): getEnv("LOG_IS_FILE").string.parseBool else: false
#   LOG_DIR* = if existsEnv("LOG_DIR"): getEnv("LOG_DIR").string else: ""
