ARG DEBIAN_VERSION=13.6
ARG GITEA_VERSION=1.27.3

#
# Gitea 1.27.3 requires:
#   Go   >= 1.26.4
#   Node >= 24 (recommended by Gitea build docs)
#
FROM docker.io/library/golang:1.26.7-trixie AS GO

FROM docker.io/library/node:24.20.0-trixie AS BUILD

ARG IMAGE_NAME="gitea"
ARG IMAGE_VERSION="${GITEA_VERSION}"
ARG GITEA_BRANCH="v${IMAGE_VERSION}"

# Bring Go into the Node build image.
COPY --from=GO /usr/local/go /usr/local/go

ENV PATH="/usr/local/go/bin:${PATH}"

RUN apt-get update \
 && apt-get install -y --no-install-recommends \
      bash \
      build-essential \
      ca-certificates \
      git \
 && rm -rf /var/lib/apt/lists/* \
 && npm install --global pnpm@11.9.0 \
 && git config --global advice.detachedHead false \
 && git clone \
      --branch "${GITEA_BRANCH}" \
      --depth 1 \
      https://github.com/go-gitea/gitea.git

WORKDIR /gitea

RUN go version \
 && node --version \
 && npm --version \
 && pnpm --version \
 && TAGS="bindata" make build


# ═══════════════════════════════════════════════════════════════════════
# Runtime
# ═══════════════════════════════════════════════════════════════════════

# This is redundant because the node code is compiled into the gitea binary
# ARG NODE_VERSION=24.20.0
# FROM docker.io/gautada/node:${NODE_VERSION} AS CONTAINER

FROM docker.io/gautada/debian:${DEBIAN_VERSION} AS CONTAINER

#
# ARG variables have stage scope. Redeclare them here.
#
ARG IMAGE_NAME="gitea"
ARG IMAGE_VERSION="${GITEA_VERSION}"

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
# │ PACKAGES           │
# ╰――――――――――――――――――――╯
RUN apt-get update \
 && apt-get upgrade -y \
 && apt-get install -y --no-install-recommends \
      bash \
      git \
      openssh-client \
      postgresql-client-17 \
 && rm -rf /var/lib/apt/lists/*

# ╭――――――――――――――――――――╮
# │ USER               │
# ╰――――――――――――――――――――╯
ARG OLDUSER=debian
ARG USER=gitea

RUN /usr/sbin/usermod -l "$USER" "$OLDUSER" \
 && /usr/sbin/usermod -d "/home/$USER" -m "$USER" \
 && /usr/sbin/groupmod -n "$USER" "$OLDUSER" \
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
# │ ENTRYPOINT         │
# ╰――――――――――――――――――――╯
COPY etc/services.d/gitea/run /etc/services.d/gitea/run
COPY usr/bin/container-version /usr/bin/container-version

# ╭――――――――――――――――――――╮
# │ APPLICATION        │
# ╰――――――――――――――――――――╯
# /opt/gitea and /etc/gitea are needed for legacy support (mostly webhooks).
RUN ln -fsv /mnt/volumes/data /mnt/volumes/container \
 && ln -fsv /mnt/volumes/configuration /mnt/volumes/configmaps \
 && /bin/mkdir -p \
      /etc/gitea \
      /opt/gitea \
      /etc/container/secrets \
 && /bin/ln -fsv \
      /etc/container/app.ini \
      /etc/gitea/app.ini \
 && /bin/ln -fsv \
      /mnt/volumes/configmaps/app.ini \
      /etc/container/app.ini \
 && /bin/ln -fsv \
      /mnt/volumes/container/app.ini \
      /mnt/volumes/configmaps/app.ini \
 && /bin/ln -fsv \
      /etc/container/app.ini \
      /opt/gitea/app.ini

COPY --from=BUILD /gitea/gitea /usr/bin/gitea
COPY --from=BUILD /gitea/custom/conf/app.example.ini /etc/gitea/app.example.ini

# ╭――――――――――――――――――――╮
# │ SETTINGS           │
# ╰――――――――――――――――――――╯
# USER $USER
EXPOSE 8080/tcp
WORKDIR /home/$USER
