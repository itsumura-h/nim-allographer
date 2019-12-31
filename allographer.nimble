# Package

version       = "0.6.0"
author        = "Hidenobu Itsumura @dumblepytech1 as 'medy'"
description   = "A Nim query builder library inspired by Laravel/PHP and Orator/Python"
license       = "MIT"
srcDir        = "src"
backend       = "c"
bin           = @["allographer/cli/dbtool"] # ここはパッケージの名前によって変わる
binDir        = "src/bin"
installExt    = @["nim"]
skipDirs      = @["allographer/cli"]

# Dependencies

requires "nim >= 1.0.0"
requires "cligen >= 0.9.38"
requires "progress >= 1.1.1"

import strformat
from os import `/`

task docs, "Generate API documents":
  let
    deployDir = "deploy" / "docs"
    pkgDir = srcDir / "allographer"
    srcFiles = @[
      "query_builder",
      "schema_builder",
    ]

  if existsDir(deployDir):
    rmDir deployDir
  for f in srcFiles:
    let srcFile = pkgDir / f & ".nim"
    exec &"nim doc --hints:off --project --out:{deployDir} --index:on {srcFile}"
