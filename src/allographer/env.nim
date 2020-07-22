import os, strutils
import dotenv

type Env* = ref object

proc newEnv*(fileName=".env"):Env =
  let env = getCurrentDir().initDotEnv(fileName)
  env.load()
  return Env()

proc getStr*(this:Env, key:string, default=""):string =
  var r = getEnv(key)
  if r.len == 0:
    return default
  return r

proc getInt*(this:Env, key:string, default=0):int =
  var r = getEnv(key)
  if r.len == 0:
    return default
  return r.parseInt

proc getFloat*(this:Env, key:string, default=0.0):float =
  var r = getEnv(key)
  if r.len == 0:
    return default
  return r.parseFloat

proc getBool*(this:Env, key:string, default=false):bool =
  var r = getEnv(key)
  if r.len == 0:
    return default
  return r.parseBool
