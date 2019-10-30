import
  functions/config
  # functions/migrate


when isMainModule:
  import cligen
  dispatchMulti([config.makeConf], [config.loadConf])
