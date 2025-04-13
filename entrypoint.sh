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

container_entrypoint() {
 log "-i" "entrypoint" "default"
 /usr/bin/pgrep gitea > /dev/null
 TEST=$?
 if [ $TEST -eq 1 ] ; then
  log "-i" "entrypoint" "Blocking application - gitea($(app_version))"
 /usr/bin/gitea --config /etc/container/app.ini --work-path /mnt/volumes/container --custom-path /mnt/volumes/container/custom web
 fi
}
