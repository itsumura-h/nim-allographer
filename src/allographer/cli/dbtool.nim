import
  functions/config

when isMainModule:
  import cligen
  dispatchMulti(
    [config.makeConf]#, [config.loadConf]
  )
