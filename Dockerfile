# OpenClaw + aibtc Docker Image
# Based on official OpenClaw image with aibtc-mcp-server pre-installed

FROM ghcr.io/openclaw/openclaw:latest

# Install aibtc-mcp-server and mcporter globally
USER root
RUN npm install -g @aibtc/mcp-server mcporter

# Set default network
ENV NETWORK=mainnet

# Switch back to node user
USER node

# Default command runs the gateway
CMD ["node", "dist/index.js", "gateway", "--bind", "lan", "--port", "18789"]
