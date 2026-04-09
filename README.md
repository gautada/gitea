# gitea

[gitea](https://gitea.io/en-us/)  Gitea is a community managed lightweight code
hosting solution.

Check the [version](https://github.com/go-gitea/gitea).

## Features

- **git** - Provides a complete git host.

## Upgrading

Setup a `testdb` so the upgrade can be tested.

Dump the existing database

```sh
pg_dump -U gitea giteadb > giteadb.sql
```

Create the test db

```sh
createdb -h localhost -U gitea -T template0 testdb
```

Restore the old db to new db

```sh
psql -U gitea testdb -f giteadb.sql
```

Drop the test db after the test

```sh
dropdb testdb
```

Run the upgrade doctor

```sh
/usr/bin/gitea -c /mnt/volumes/configmaps/gitea.ini doctor \
  recreate-table project system_setting
```

## JWT secrets

The container entrypoint reads JWT secrets from files so they can be provided via
mounted Kubernetes/OpenShift secrets (or Docker secrets) instead of placing
them directly in `app.ini`.

| Secret | Default file path | Environment override |
| ------ | ----------------- | -------------------- |
| Core JWT secret | `/mnt/volumes/secrets/jwt-secret` | `JWT_SECRET_FILE` |
| LFS JWT secret | `/mnt/volumes/secrets/lfs-jwt-secret` | `LFS_JWT_SECRET_FILE` |
| OAuth2 JWT secret | `/mnt/volumes/secrets/oauth2-jwt-secret` | `OAUTH2_JWT_SECRET_FILE`

If `GITEA__security__<secret>` variables are already set they take precedence;
otherwise, the entrypoint exports the values from the files (stripping trailing
newlines) before launching Gitea.
