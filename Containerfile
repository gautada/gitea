ARG DEBIAN_VERSION=13.6

ARG IMAGE_NAME="gitea"
ARG IMAGE_VERSION="1.23.5"
ARG GITEA_BRANCH="v${IMAGE_VERSION}"

FROM docker.io/gautada/debian:${DEBIAN_VERSION} AS BUILD

RUN apt-get update \
 && apt-get install -y --no-install-recommends \
      bash \
      build-essential \
      ca-certificates \
      git \
      golang \
      nodejs \
      npm \
 && rm -rf /var/lib/apt/lists/* \
 && git config --global advice.detachedHead false \
 && git clone \
      --branch "${GITEA_BRANCH}" \
      --depth 1 \
      https://github.com/go-gitea/gitea.git

WORKDIR /gitea

RUN TAGS="bindata" make build


FROM docker.io/gautada/debian:${DEBIAN_VERSION} AS CONTAINER

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
# Rename the base debian user to hermes. Follows the same pattern as other
# gautada containers (e.g. gautada/homepage).
ARG OLDUSER=debian
ARG USER=gitea
RUN /usr/sbin/usermod -l $USER $OLDUSER \
 && /usr/sbin/usermod -d /home/$USER -m $USER \
 && /usr/sbin/groupmod -n $USER $OLDUSER \
 && /bin/echo "$USER:$USER" | /usr/sbin/chpasswd 

# ╭――――――――――――――――――――╮
# │ PRIVILEGES         │
# ╰――――――――――――――――――――╯
COPY etc/container/privileges /etc/container/privileges

# ╭――――――――――――――――――――╮
# │ BACKUP             │
# ╰――――――――――――――――――――╯
COPY etc/container/backup /etc/container/backup

# ╭――――――――――――――――――――╮
# │ ENTTRYPOINT        │
# ╰――――――――――――――――――――╯
COPY etc/services.d/gitea/run /etc/services.d/gitea/run
# COPY entrypoint.sh /etc/container/entrypoint

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

COPY --from=BUILD /gitea/gitea /usr/bin/gitea
COPY --from=BUILD /gitea/custom/conf/app.example.ini /etc/gitea/app.example.ini

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
