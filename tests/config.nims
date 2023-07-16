import os

switch("path", "$projectDir/../src")
putEnv("DB_SQLITE", $true)
# putEnv("DB_MYSQL", $true)
putEnv("DB_MARIADB", $true)
putEnv("DB_POSTGRES", $true)
