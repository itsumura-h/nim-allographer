when isMainModule:
  import cligen
  import command
  dispatchMulti([command.makeConf], [command.loadConf])