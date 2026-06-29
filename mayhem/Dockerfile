# syntax=docker/dockerfile:1.7
FROM ghcr.io/mayhemheroes/base:20260621

ARG COMMIT
ARG REPO_URL
ARG SOURCE_DATE_EPOCH
ARG SANITIZER_FLAGS

ARG RUST_CHANNEL=nightly-2025-01-15
ARG CARGO_FUZZ_VERSION=0.12.0

ENV RUSTUP_HOME=/opt/toolchains/rust/rustup \
    CARGO_HOME=/opt/toolchains/rust/cargo \
    PATH=/opt/toolchains/rust/cargo/bin:${PATH}

USER root
RUN install -d /opt/toolchains/rust \
 && curl --proto '=https' --tlsv1.2 -fsSL https://sh.rustup.rs -o /tmp/rustup-init.sh \
 && sh /tmp/rustup-init.sh -y --no-modify-path --profile minimal \
        --default-toolchain "${RUST_CHANNEL}" \
 && rustup component add rust-src --toolchain "${RUST_CHANNEL}" \
 && cargo install cargo-fuzz --version "${CARGO_FUZZ_VERSION}" --locked \
 && rm -f /tmp/rustup-init.sh \
 && chown -R 2000:2000 /opt/toolchains/rust

# DWARF-3 anchor: prepend a clang-compiled CU so readelf -m1 sees version 3 (§6.2 item 10).
RUN install -d /opt/mayhem-dwarf3-anchor \
 && printf 'volatile int mayhem_dwarf3_anchor;\n' > /tmp/anchor.c \
 && clang -g -gdwarf-3 -c /tmp/anchor.c -o /opt/mayhem-dwarf3-anchor/anchor.o \
 && printf '#!/bin/sh\nexec cc /opt/mayhem-dwarf3-anchor/anchor.o "$@"\n' \
        > /opt/mayhem-dwarf3-anchor/cc-wrapper.sh \
 && chmod +x /opt/mayhem-dwarf3-anchor/cc-wrapper.sh \
 && rm -f /tmp/anchor.c

USER mayhem
WORKDIR /mayhem
COPY --chown=2000:2000 . /mayhem

RUN bash mayhem/build.sh

RUN if [ -f mayhem/test.sh ]; then bash mayhem/test.sh; else echo "no mayhem/test.sh — repo ships no functional tests"; fi

LABEL org.opencontainers.image.source="${REPO_URL}" \
      org.opencontainers.image.revision="${COMMIT}" \
      rlenv.tier="commit" \
      rlenv.source_date_epoch="${SOURCE_DATE_EPOCH}" \
      rlenv.user="mayhem"

USER mayhem
WORKDIR /mayhem
