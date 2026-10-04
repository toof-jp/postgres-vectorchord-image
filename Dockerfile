ARG BASE_IMAGE=ghcr.io/cloudnative-pg/postgresql:16-standard-trixie
ARG VCHORD_VERSION=0.5.3
ARG PGVECTOR_VERSION=v0.8.1

FROM ${BASE_IMAGE} AS builder
USER root
ARG PGVECTOR_VERSION
RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        postgresql-server-dev-16 \
        make \
        gcc \
        git \
        ca-certificates \
    && rm -rf /var/lib/apt/lists/*
WORKDIR /tmp
RUN git clone --branch ${PGVECTOR_VERSION} --depth 1 https://github.com/pgvector/pgvector.git \
    && cd pgvector \
    && make USE_PGXS=1 OPTFLAGS='-march=x86-64-v3 -ftree-vectorize' \
    && make USE_PGXS=1 OPTFLAGS='-march=x86-64-v3 -ftree-vectorize' DESTDIR=/tmp/install install

FROM ${BASE_IMAGE}
USER root
ARG VCHORD_VERSION
ENV DEBIAN_FRONTEND=noninteractive
RUN apt-get update \
    && apt-get install -y --no-install-recommends wget ca-certificates \
    && wget -nv -O /tmp/vchord.deb \
        https://github.com/tensorchord/VectorChord/releases/download/${VCHORD_VERSION}/postgresql-16-vchord_${VCHORD_VERSION}-1_amd64.deb \
    && apt-get install -y --no-install-recommends /tmp/vchord.deb \
    && rm /tmp/vchord.deb \
    && rm -rf /var/lib/apt/lists/*

COPY --from=builder /tmp/install/usr/lib/postgresql/ /usr/lib/postgresql/
COPY --from=builder /tmp/install/usr/share/postgresql/ /usr/share/postgresql/

USER postgres
