# Base Jenkins image
FROM jenkins/jenkins:lts

USER root

# Install curl, gnupg2, ca-certificates, apt-transport-https, git, Docker CLI, Node.js
RUN apt-get update && \
    apt-get install -y curl gnupg2 ca-certificates apt-transport-https git lsb-release sudo iproute2 && \
    curl -fsSL https://deb.nodesource.com/setup_20.x | bash - && \
    apt-get install -y nodejs docker.io && \
    npm install -g npm@latest && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

# Verify installations
RUN node -v && npm -v && docker --version && git --version

# Switch back to Jenkins user
USER jenkins
