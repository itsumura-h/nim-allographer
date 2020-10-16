import os

# DB Connection
# putEnv("DB_DRIVER", "sqlite")
# putEnv("DB_CONNECTION", "/root/project/example/db.sqlite3")
# putEnv("DB_DRIVER", "mysql")
# putEnv("DB_CONNECTION", "mysql:3306")
putEnv("DB_DRIVER", "postgres")
putEnv("DB_CONNECTION", "postgres:5432")
putEnv("DB_USER", "user")
putEnv("DB_PASSWORD", "Password!")
putEnv("DB_DATABASE", "allographer")
putEnv("DB_MAX_CONNECTION", "95")
putEnv("DB_TIMEOUT", "1000")

# Logging
putEnv("LOG_IS_DISPLAY", "false")
putEnv("LOG_IS_FILE", "false")
putEnv("LOG_DIR", "/root/project/logs")
