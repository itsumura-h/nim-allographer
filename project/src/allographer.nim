import base, grammars, exec
export base, grammars, exec


when isMainModule:
  import cligen
  import command
  dispatchMulti([command.conf])
