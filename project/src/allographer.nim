import base, grammars, exec, database
export base, grammars, exec, database


when isMainModule:
  import cligen
  import command
  dispatchMulti([command.makeConf], [command.loadConf])
