# Base image
FROM node:20-bookworm-slim

# Environment variables
ENV PUPPETEER_SKIP_DOWNLOAD=true
ENV PUPPETEER_SKIP_CHROMIUM_DOWNLOAD=true
ENV PUPPETEER_BROWSER_PATH=google-chrome-stable

# Set working directory
WORKDIR /metrics

# Setup basic dependencies
RUN apt-get update \
  && apt-get install -y --no-install-recommends \
     wget gnupg ca-certificates curl unzip git python3 xz-utils \
  && rm -rf /var/lib/apt/lists/*

# Install Google Chrome
RUN wget -q -O - https://dl-ssl.google.com/linux/linux_signing_key.pub | gpg --dearmor -o /usr/share/keyrings/googlechrome-linux-keyring.gpg \
  && echo "deb [arch=amd64 signed-by=/usr/share/keyrings/googlechrome-linux-keyring.gpg] http://dl.google.com/linux/chrome/deb/ stable main" > /etc/apt/sources.list.d/google-chrome.list \
  && apt-get update \
  && apt-get install -y --no-install-recommends \
     google-chrome-stable fonts-ipafont-gothic fonts-wqy-zenhei fonts-thai-tlwg fonts-kacst fonts-freefont-ttf libxss1 libx11-xcb1 libxtst6 lsb-release \
  && rm -rf /var/lib/apt/lists/*

# Install Deno (for Splatoon plugin and other scripts)
RUN curl -fsSL https://deno.land/x/install/install.sh | DENO_INSTALL=/usr/local sh

# Install Ruby and Licensed gem (for Licenses plugin)
# We use --no-document to save time and space
RUN apt-get update \
  && apt-get install -y --no-install-recommends \
     ruby-full make g++ cmake pkg-config libssl-dev \
  && gem install licensed --no-document \
  && rm -rf /var/lib/apt/lists/*

# Install node modules
# We copy package files first to leverage Docker layer caching
COPY package.json package-lock.json ./
RUN CI=true npm ci --no-audit --no-fund

# Copy repository
COPY . .

# Build and set permissions
RUN chmod +x /metrics/source/app/action/index.mjs \
  && npm run build

# Execute GitHub action
ENTRYPOINT ["node", "/metrics/source/app/action/index.mjs"]
