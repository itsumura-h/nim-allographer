import os, parsecfg

proc logger*(output: any) =
  # get Config file
  let confPath = getCurrentDir() & "/config/database.ini"

  var conf = loadConfig(confPath)
  var isDisplayString = conf.getSectionValue("Log", "display")
  if isDisplayString == "true":
    echo $output