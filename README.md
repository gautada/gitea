# gitea

[gitea](https://gitea.io/en-us/)  Gitea is a community managed lightweight code hosting solution.

## Features

- **git** - Provides a complete git host.

**UPGRADING**

Setup a `testdb` so the upgrade can be tested.

Dump the existing database
```
pg_dump -U gitea giteadb > giteadb.sql
``` 

Create the test db
```
createdb -h localhost -U gitea -T template0 testdb
```

Restore the old db to new db
```
psql -U gitea testdb -f giteadb.sql
```

Drop the test db after the test
```
dropdb testdb

```

Run the upgrade doctor
```
/usr/bin/gitea -c /mnt/volumes/configmaps/gitea.ini doctor recreate-table project system_setting
```
