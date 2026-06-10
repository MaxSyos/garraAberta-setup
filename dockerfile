FROM ubuntu:24.04

ENV DEBIAN_FRONTEND=noninteractive

RUN curl -fsSL https://deb.nodesource.com/setup_22.x | bash - && \
    apt-get update && apt-get install -y \
    curl \
    wget \
    git \
    unzip \
    nano \
    vim \
    python3 \
    python3-pip \
    python3-venv \
    build-essential \
    ca-certificates \
    nodejs \
    npm \
    openssh-client \
 && rm -rf /var/lib/apt/lists/*

RUN curl -fsSL https://hermes-agent.nousresearch.com/install.sh | bash

WORKDIR /workspace

COPY entrypoint.sh /entrypoint.sh

RUN chmod +x /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]
