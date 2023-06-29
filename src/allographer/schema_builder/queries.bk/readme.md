- not null
- unique
- default
- unsigned
- foreign key
- index

## Sqlite

- not null
  - `NOT NULL`
- unique
  - `UNIQUE`
- default
  - `DEFAULT 1`
- unsigned
  - `CHECK ('columnName' >= 0)`
- foreign key
  - delete = `RESTRICT` / `CASCADE` / `SET NULL` / `NO ACTION`
  - `FOREIGN KEY('columnName') REFERENCES "tableName"('columnnName') ON DELETE {delete}`

### create tabel
```sql
CREATE TABLE IF NOT EXISTS "tableName" ('columnName' {type} {not null} {unique} {default} {unsigned}, {foreign key})
CREATE INDEX IF NOT EXISTS "tableName_columnName_index" ON "tableName"('columnName')
```

- [x] sample
```sql
CREATE TABLE IF NOT EXISTS "t1" ('id' INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT);
CREATE TABLE IF NOT EXISTS "t2" ('id' INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT, 't1_id' INTEGER NOT NULL, 'unique' INTEGER NOT NULL UNIQUE, 'index' INTEGER NOT NULL, FOREIGN KEY('t1_id') REFERENCES "t1"('id') ON DELETE SET NULL);
CREATE INDEX IF NOT EXISTS "t2_index_index" ON "t2"('index');
```


### alter table
#### add column
```sql
ALTER TABLE "tableName" ADD COLUMN 'columnName' {type} {not null} {default} {unsigned};
```

- [ ] sample
```sql
CREATE TABLE "t1" ('c2' INTEGER);
ALTER TABLE "t1" ADD COLUMN 'c2' INTEGER NOT NULL DEFAULT 1 CHECK ('c2' >= 0);
```

##### increment
- create tmp table with new columns
- move data from old table
- drop old table
- rename tmp table to old table

- [x] sample
```sql
CREATE TABLE "t1" ('c1' INTEGER);
CREATE TABLE "tmp" ('id' INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT, 'c1' INTEGER);
INSERT INTO "tmp"('c1') SELECT 'c1' FROM "t1";
DROP TABLE IF EXISTS "t1";
ALTER TABLE "tmp" RENAME TO "t1";
```


##### foreign key
```sql
ALTER TABLE "tableName" ADD COLUMN 'refTable_id' {type} REFERENCES "tableName"('id') ON DELETE SET NULL;
```

- [x] sample
```sql
ALTER TABLE "t2" ADD COLUMN 't1_id' INTEGER REFERENCES "t1"('id') ON DELETE SET NULL;
```

##### unique
```sql
ALTER TABLE "tableName" ADD COLUMN 'columnName' {type} {not null} {default} {unsigned};
CREATE UNIQUE INDEX IF NOT EXISTS "tableName_columnName_unique" ON "tableName"('columnName');
```

- [ ] sample
```sql
ALTER TABLE "t2" ADD COLUMN 'c3' INTEGER NOT NULL DEFAULT 1 CHECK ('c3' >= 0);
CREATE UNIQUE INDEX IF NOT EXISTS "t2_c3_unique" ON "t2"('c3');
```

##### index
```sql
ALTER TABLE "tableName" ADD COLUMN 'columnName' {type} {not null} {default} {unsigned};
CREATE INDEX IF NOT EXISTS "tableName_columnName_index" ON "tableName"('columnName');
```

- [x] sample
```sql
ALTER TABLE "t2" ADD COLUMN 'c4' INTEGER NOT NULL DEFAULT 1 CHECK ('c4' >= 0);
CREATE INDEX "t2_c4_index" ON "t2"('c4');
```

#### change column
- create tmp table with new columns
- move data from old table
- drop old table
- rename tmp table to old table

## Postgres

- not null
  - `NOT NULL`
- unique
  - `UNIQUE`
- default
  - `DEFAULT 1`
- unsigned
  - `CHECK ('columnName' >= 0)`
- foreign key
  - delete = `RESTRICT` / `CASCADE` / `SET NULL` / `NO ACTION`
  - `FOREIGN KEY('columnName') REFERENCES "tableName"('columnnName') ON DELETE {delete}`

### create tabel
```sql
CREATE TABLE IF NOT EXISTS "tableName" ("columnName" {type} {not null} {unique} {default} {unsigned}, {foreign key})
CREATE INDEX IF NOT EXISTS "tableName_columnName_index" ON "tableName"("columnName")
```

- [x] sample
```sql
CREATE TABLE IF NOT EXISTS "t1" ("id" SERIAL PRIMARY KEY);
CREATE TABLE IF NOT EXISTS "t2" ("id" SERIAL PRIMARY KEY, "t1_id" INTEGER NOT NULL, "unique" INTEGER NOT NULL UNIQUE, "index" INTEGER NOT NULL, FOREIGN KEY("t1_id") REFERENCES "t1"("id") ON DELETE SET NULL);
CREATE INDEX IF NOT EXISTS "t2_index_index" ON "t2"("index");
```

### alter table
#### add column
```sql
ALTER TABLE "tableName" ADD COLUMN "columnName" {type} {not null} {default} {unsigned};
```

- [x] sample
```sql
CREATE TABLE "t1" ("intger" INTEGER);
ALTER TABLE "t1" ADD COLUMN "c1" INTEGER NOT NULL DEFAULT 1 CHECK("c1" >= 0);
```

##### increment
```sql
ALTER TABLE "tableName" ADD COLUMN "id" SERIAL PRIMARY KEY;
```

- [x] sample
```sql
CREATE TABLE "t1" ("intger" INTEGER);
ALTER TABLE "t1" ADD COLUMN "id" SERIAL PRIMARY KEY;
```

##### foreign key
```sql
ALTER TABLE "tableName" ADD COLUMN "columnName" BIGINT {not null} {default} {unsigned}
ALTER TABLE "tableName" ADD FOREIGN KEY("columnName") REFERENCES "tableName"("columnName") ON DELETE {delete}
```

- [x] sample
```sql
CREATE TABLE "t1" ("id" SERIAL PRIMARY KEY);
CREATE TABLE "t2" ("intger" INTEGER);
ALTER TABLE "t2" ADD COLUMN "t1_id" BIGINT NOT NULL DEFAULT 1 CHECK("t1_id" >= 0);
ALTER TABLE "t2" ADD FOREIGN KEY("t1_id") REFERENCES "t1"("id") ON DELETE SET NULL;
```

##### unique
```sql
ALTER TABLE "tableName" ADD COLUMN "integer" {type} {not null} CONSTRAINT "tableName_columnName_unique" UNIQUE {check}
```

- [x] sample
```sql
CREATE TABLE "t1" ("id" SERIAL PRIMARY KEY);
ALTER TABLE "t1" ADD COLUMN "index" INTEGER NOT NULL CONSTRAINT "t1_unique_unique" UNIQUE CHECK("index" >= 0);
```

##### index
```sql
ALTER TABLE "tableName" ADD COLUMN "columnName" {type} {not null} {default} CONSTRAINT "t1_unique_unique" {unsigned};
CREATE INDEX IF NOT EXISTS "tableName_columnName_index" ON "tableName"("columnName");
```

- [x] sample
```sql
CREATE TABLE "t1" ("id" SERIAL PRIMARY KEY);
ALTER TABLE "t1" ADD COLUMN "index" INTEGER NOT NULL DEFAULT 1 CONSTRAINT "t1_unique_unique" CHECK("index" >= 0);
CREATE INDEX IF NOT EXISTS "t1_index_index" ON "t1"("index");
```


#### change column

##### not null
##### default
##### unique
##### unsigned
##### index
