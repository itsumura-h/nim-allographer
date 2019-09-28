# Package

version       = "0.1.0"
author        = "Hidenobu Itsumura"
description   = "A Nim query builder library inspired by Laravel/PHP and Orator/Python"
license       = "MIT"
srcDir        = "src"

backend       = "cpp"

# Dependencies

requires "nim >= 1.0.0"

skipDirs = @["coverage", "docker", "tests"]
skipExt = @["sh"]