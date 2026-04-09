ARG ALPINE_VERSION=latest
FROM docker.io/gautada/alpine:$ALPINE_VERSION AS build

# ╭――――――――――――――――――――╮
# │ VARIABLES          │
# ╰――――――――――――――――――――╯
ARG IMAGE_NAME="gitea"
ARG IMAGE_VERSION="1.23.5"
ARG GITEA_BRANCH=v"$IMAGE_VERSION"

WORKDIR /
RUN /sbin/apk add --no-cache bash build-base git go nodejs npm \
 && git config --global advice.detachedHead false \
 && git clone --branch "v${IMAGE_VERSION}" --depth 1 https://github.com/go-gitea/gitea.git

WORKDIR /gitea
RUN TAGS="bindata" make build






FROM docker.io/gautada/alpine:$ALPINE_VERSION AS container

# ╭――――――――――――――――――――╮
# │ METADATA           │
# ╰――――――――――――――――――――╯
LABEL org.opencontainers.image.title="${IMAGE_NAME}"
LABEL org.opencontainers.image.description="A gitea container."
LABEL org.opencontainers.image.url="https://hub.docker.com/r/gautada/${IMAGE_NAME}"
LABEL org.opencontainers.image.source="https://github.com/gautada/${IMAGE_NAME}"
LABEL org.opencontainers.image.version="${IMAGE_VERSION}"
LABEL org.opencontainers.image.license="Upstream"

# ╭――――――――――――――――――――╮
# │ USER               │
# ╰――――――――――――――――――――╯
ARG USER=gitea
# Set shell to /bin/ash and enable pipefail for Alpine-based images
# SHELL ["/bin/ash", "-o", "pipefail", "-c"]
RUN /usr/sbin/usermod -l $USER alpine \
 && /usr/sbin/usermod -d /home/$USER -m $USER \
 && /usr/sbin/groupmod -n $USER alpine \
 && /bin/echo "$USER:$USER" | /usr/sbin/chpasswd

# ╭――――――――――――――――――――╮
# │ PRIVILEGES         │
# ╰――――――――――――――――――――╯
COPY privileges /etc/container/privileges

# ╭――――――――――――――――――――╮
# │ BACKUP             │
# ╰――――――――――――――――――――╯
COPY backup /etc/container/backup

# ╭――――――――――――――――――――╮
# │ ENTTRYPOINT        │
# ╰――――――――――――――――――――╯
COPY entrypoint.sh /etc/container/entrypoint

# ╭――――――――――――――――――――╮
# │ APPLICATION        │
# ╰――――――――――――――――――――╯
# /opt/gitea and /etc/gitea are needed for legacy support (mostly webhooks).
RUN /bin/mkdir -p /etc/gitea /opt/gitea /etc/container/secrets \
 && /bin/ln -fsv /etc/container/app.ini /etc/gitea/app.ini \
 && /bin/ln -fsv /mnt/volumes/configmaps/app.ini /etc/container/app.ini \
 && /bin/ln -fsv /mnt/volumes/container/app.ini \
                 /mnt/volumes/configmaps/app.ini \
# RUN /bin/ln -fsv /mnt/volumes/secrets/postgresql-cert.pem \
#                  /etc/container/secrets/postgresql-cert.pem 
# RUN /bin/ln -fsv /mnt/volumes/secrets/postgresql-key.pem \
#                  /etc/container/secrets/postgresql-key.pem 
 && /bin/ln -fsv /etc/container/app.ini /opt/gitea/app.ini \
 && /sbin/apk add --no-cache bash git openssh-client postgresql17-client

COPY --from=build /gitea/gitea /usr/bin/gitea
COPY --from=build /gitea/custom/conf/app.example.ini /etc/gitea/app.example.ini

# ╭――――――――――――――――――――╮
# │ SETTINGS           │
# ╰――――――――――――――――――――╯
USER $USER
VOLUME /mnt/volumes/backup
VOLUME /mnt/volumes/configmaps
VOLUME /mnt/volumes/container
VOLUME /mnt/volumes/secrets
EXPOSE 8080/tcp
WORKDIR /home/$USER
