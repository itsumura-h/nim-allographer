type UserTable* = object
  id*: string
  name*: string
  email*: string
  password*: string
  created_at*: string
  updated_at*: string

type PostTable* = object
  id*: string
  title*: string
  content*: string
  user_id*: string
  created_at*: string
  updated_at*: string
