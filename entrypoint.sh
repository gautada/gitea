#!/bin/sh
#
# entrypoint: Located at `/etc/container/entrypoint` this script is the custom
#             entry for a container as called by `/usr/bin/container-entrypoint` set
#             in the upstream [alpine-container](https://github.com/gautada/alpine-container).
#             The default template is kept in
#             [gist](https://gist.github.com/gautada/f185700af585a50b3884ad10c2b02f98)

# ENTRYPOINT_PARAMS="$@"
# . /etc/profile

container_version() {
 /usr/bin/gitea --version | awk -F ' ' '{print $3}'
}

DEFAULT_JWT_SECRET_FILE="/mnt/volumes/secrets/jwt-secret"
DEFAULT_LFS_JWT_SECRET_FILE="/mnt/volumes/secrets/lfs-jwt-secret"
DEFAULT_OAUTH2_JWT_SECRET_FILE="/mnt/volumes/secrets/oauth2-jwt-secret"

load_secret_from_file() {
 VAR_NAME="$1"
 FILE_PATH="$2"
 eval "CURRENT_VALUE=\${$VAR_NAME-}"
 if [ -n "$CURRENT_VALUE" ]; then
  return
 fi
 if [ -f "$FILE_PATH" ]; then
  SECRET_VALUE=$(tr -d '\r\n' < "$FILE_PATH")
  export "$VAR_NAME=$SECRET_VALUE"
 fi
}

ensure_jwt_secrets() {
 load_secret_from_file "GITEA__security__JWT_SECRET" "${JWT_SECRET_FILE:-$DEFAULT_JWT_SECRET_FILE}"
 load_secret_from_file "GITEA__security__LFS_JWT_SECRET" "${LFS_JWT_SECRET_FILE:-$DEFAULT_LFS_JWT_SECRET_FILE}"
 load_secret_from_file "GITEA__security__OAUTH2_JWT_SECRET" "${OAUTH2_JWT_SECRET_FILE:-$DEFAULT_OAUTH2_JWT_SECRET_FILE}"
}

container_entrypoint() {
 ensure_jwt_secrets
 log "-i" "entrypoint" "default"
 /usr/bin/pgrep gitea > /dev/null
 TEST=$?
 if [ $TEST -eq 1 ] ; then
  log "-i" "entrypoint" "Blocking application - gitea($(app_version))"
 /usr/bin/gitea --config /etc/container/app.ini --work-path /mnt/volumes/container --custom-path /mnt/volumes/container/custom web
 fi
 # tail -f /dev/null
}
