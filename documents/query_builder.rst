======================
Example: Query Builder
======================

`back <../README.md>`_

.. contents:: Table of contents

SELECT
======

When it returns following table

==  =====  ====  ========================  ==== ========
id  float  char  datetime                  null is_admin
==  =====  ====  ========================  ==== ========
1   3.14   char  2019-01-01 12:00:00.1234       1
==  =====  ====  ========================  ==== ========

Return JsonNode
---------------

.. code-block:: nim

   import allographer/query_builder

   echo RDB().table("test")
       .select("id", "float", "char", "datetime", "null", "is_admin")
       .get()

.. code-block:: nim

   >> @[
     {
       "id": 1,                                # JInt
       "float": 3.14,                          # JFloat
       "char": "char",                         # JString
       "datetime": "2019-01-01 12:00:00.1234", # JString
       "null": null                            # JNull
       "is_admin": true                        # JBool
     }
   ]

Return Object
-------------

If object is defined and set arg of get/getRaw/first/find, response will be object as ORM

.. code-block:: nim

   import allographer/query_builder

   type Typ = ref object
     id: int
     float: float
     char: string
     datetime: string
     null: string
     is_admin: bool

   var rows = RDB().table("test")
             .select("id", "float", "char", "datetime", "null", "is_admin")
             .get(Typ)

.. code-block:: nim

   echo rows[0].id
   >> 1                            # int

   echo rows[0].float
   >> 3.14                         # float

   echo rows[0].char
   >> "char"                       # string

   echo rows[0].datetime
   >> "2019-01-01 12:00:00.1234"   # string

   echo rows[0].null
   >> ""                           # string

   echo rows[0].is_admin
   >> true                         # bool

get
----

Retrieving all row from a table

.. code-block:: nim

   let users = RDB().table("users").get()
   for user in users:
     echo user["name"]

first
-----

Retrieving a single row from a table

.. code-block:: nim

   let user = RDB()
               .table("users")
               .where("name", "=", "John")
               .first()
   echo user["name"]
