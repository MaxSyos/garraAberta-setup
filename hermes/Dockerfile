FROM node:22-bullseye

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y \
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
    openssh-client \
 && rm -rf /var/lib/apt/lists/*

RUN curl -fsSL https://hermes-agent.nousresearch.com/install.sh | bash && \
    cd /usr/local/lib/hermes-agent && \
    npm install --workspace web && \
    npm run build -w web

WORKDIR /workspace

COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

EXPOSE 8080
ENTRYPOINT ["/entrypoint.sh"]
