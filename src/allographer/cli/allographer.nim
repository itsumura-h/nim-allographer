import ./functions/create_active_record


when isMainModule:
  import cligen
  dispatchMulti(
    [createActiveRecord.activeRecord],
  )
