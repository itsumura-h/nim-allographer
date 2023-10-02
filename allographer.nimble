# Package

version       = "0.26.0"
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
when (NimMajor, NimMinor) > (1, 6):
  requires "db_connector >= 0.1.0"
  requires "checksums >= 0.1.0"


import strformat, os

task test, "run testament test":
  exec "testament p 'tests/v2/*/test_*.nim'"
  for kind, path in walkDir(getCurrentDir() / "tests"):
    if not path.contains(".") and path.fileExists():
      exec "rm -f " & path

task test_v1, "run testament test":
  exec "testament p 'tests/v1/*/test_*.nim'"
  for kind, path in walkDir(getCurrentDir() / "tests"):
    if not path.contains(".") and path.fileExists():
      exec "rm -f " & path

task docs, "Generate API documents":
  let
    deployDir = "docs"
    pkgDir = srcDir / "allographer"
    srcFiles = @[
      "connection",
      "query_builder",
      "schema_builder",
    ]

  if dirExists(deployDir):
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
  generateToc("./documents/rdb")
  generateToc("./documents/surrealdb")
