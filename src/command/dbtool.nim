import
  functions/config,
  functions/migration


when isMainModule:
  import cligen
  dispatchMulti(
    [config.makeConf], [config.loadConf], [migration.migrate]
  )
