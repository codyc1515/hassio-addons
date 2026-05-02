FROM ubuntu:22.04

ARG RUNNER_VERSION="2.334.0"
ARG PYTHON_RELEASE_TAGS="3.11.15-22631496413 3.12.13-22652080177"
ARG PLAYWRIGHT_PY_VERSION="1.58.0"
ARG REQUESTS_VERSION="2.33.1"
ARG PIP_VERSION="26.0.1"
ARG TARGETARCH
ARG DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y --no-install-recommends \
    curl \
    jq \
    ca-certificates \
    git \
    lsb-release \
    sudo \
    unzip \
    docker.io \
    python3 \
    python3-pip \
    python3-venv \
    python-is-python3 \
    libglib2.0-0 \
    libnspr4 \
    libnss3 \
    libatk1.0-0 \
    libatk-bridge2.0-0 \
    libdbus-1-3 \
    libcups2 \
    libxcb1 \
    libxkbcommon0 \
    libatspi2.0-0 \
    libx11-6 \
    libxcomposite1 \
    libxdamage1 \
    libxext6 \
    libxfixes3 \
    libxrandr2 \
    libgbm1 \
    libcairo2 \
    libpango-1.0-0 \
    libasound2 \
    && rm -rf /var/lib/apt/lists/*

RUN useradd -m -d /home/runner runner \
    && usermod -aG sudo,docker runner \
    && echo "runner ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers

WORKDIR /home/runner

RUN mkdir -p /home/runner/actions-runner \
    && cd /home/runner/actions-runner \
    && ARCH="${TARGETARCH}" \
    && if [ "$ARCH" = "amd64" ]; then RUNNER_ARCH="x64"; \
       elif [ "$ARCH" = "arm64" ]; then RUNNER_ARCH="arm64"; \
       elif [ "$ARCH" = "arm/v7" ] || [ "$ARCH" = "arm" ]; then RUNNER_ARCH="arm"; \
       else echo "Unsupported arch: $ARCH" && exit 1; fi \
    && echo "Downloading runner for $RUNNER_ARCH" \
    && curl -fsSL -o actions-runner.tar.gz \
       "https://github.com/actions/runner/releases/download/v${RUNNER_VERSION}/actions-runner-linux-${RUNNER_ARCH}-${RUNNER_VERSION}.tar.gz" \
    && tar -xzf actions-runner.tar.gz \
    && rm actions-runner.tar.gz

RUN /home/runner/actions-runner/bin/installdependencies.sh

ENV AGENT_TOOLSDIRECTORY=/opt/hostedtoolcache
ENV RUNNER_TOOL_CACHE=/opt/hostedtoolcache

# Pre-seed the Python toolcache so actions/setup-python can resolve common
# versions without downloading at job runtime.
# Use pinned release tags to keep builds deterministic and avoid GitHub API
# lookups and pip/network side effects in setup scripts.
# The python-versions archives are not relocatable: their binaries are built
# with an /opt/hostedtoolcache runpath, so install them there.
RUN set -eux; \
    case "${TARGETARCH}" in \
      amd64) PYTHON_ARCH="x64" ;; \
      arm64) PYTHON_ARCH="arm64" ;; \
      *) echo "Unsupported TARGETARCH for Python toolcache: ${TARGETARCH}" && exit 1 ;; \
    esac; \
    TOOLCACHE_ROOT="${AGENT_TOOLSDIRECTORY}"; \
    mkdir -p "${TOOLCACHE_ROOT}" /tmp/python-toolcache; \
    for PYTHON_RELEASE_TAG in ${PYTHON_RELEASE_TAGS}; do \
      PYTHON_VERSION="${PYTHON_RELEASE_TAG%%-*}"; \
      ASSET_URL="https://github.com/actions/python-versions/releases/download/${PYTHON_RELEASE_TAG}/python-${PYTHON_VERSION}-linux-22.04-${PYTHON_ARCH}.tar.gz"; \
      rm -rf /tmp/python-toolcache/*; \
      curl -fsSL "${ASSET_URL}" -o /tmp/python-toolcache/python.tgz; \
      tar -xzf /tmp/python-toolcache/python.tgz -C /tmp/python-toolcache; \
      (cd /tmp/python-toolcache && AGENT_TOOLSDIRECTORY="${TOOLCACHE_ROOT}" RUNNER_TOOL_CACHE="${TOOLCACHE_ROOT}" /bin/sh ./setup.sh); \
      DEST="${TOOLCACHE_ROOT}/Python/${PYTHON_VERSION}/${PYTHON_ARCH}"; \
      "${DEST}/python" -m pip install --no-cache-dir --upgrade "pip==${PIP_VERSION}"; \
      "${DEST}/python" -m pip install --no-cache-dir "playwright==${PLAYWRIGHT_PY_VERSION}"; \
      "${DEST}/python" -m pip install --no-cache-dir "requests==${REQUESTS_VERSION}"; \
      touch "${TOOLCACHE_ROOT}/Python/${PYTHON_VERSION}/${PYTHON_ARCH}.complete"; \
    done; \
    rm -rf /tmp/python-toolcache

COPY run.sh /run.sh
RUN chmod +x /run.sh && chown -R runner:runner /home/runner /opt/hostedtoolcache /run.sh

USER runner
WORKDIR /home/runner/actions-runner

ENTRYPOINT ["/run.sh"]
