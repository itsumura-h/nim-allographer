# Package

version       = "0.19.1"
author        = "Hidenobu Itsumura @dumblepytech1 as 'medy'"
description   = "A Nim query builder library inspired by Laravel/PHP and Orator/Python"
license       = "MIT"
srcDir        = "src"
# backend       = "c"
# bin           = @["allographer/cli/dbtool"]
# binDir        = "src/bin"
# installExt    = @["nim"]
# skipDirs      = @["allographer/cli"]

# Dependencies

requires "nim >= 1.2.0"
requires "dotenv >= 1.1.1"

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

let toolImage = "basolato:tool"

task setupTool, "Setup tool docker image":
  exec &"docker build -t {toolImage} -f tool_Dockerfile ."

proc generateToc(dir: string) =
  let cwd = getCurrentDir()
  for f in listFiles(dir):
    if 3 < f.len:
      let ext = f[^3..^1]
      if ext == ".md":
        exec &"docker run --rm -v {cwd}:/work -it {toolImage} --insert --no-backup {f}"

task toc, "Generate TOC":
  generateToc(".")
  generateToc("./documents")
