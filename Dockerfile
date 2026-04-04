# Base image
FROM node:20-bookworm-slim

# Environment variables
ENV PUPPETEER_SKIP_CHROMIUM_DOWNLOAD=true
ENV PUPPETEER_BROWSER_PATH=google-chrome-stable

# Copy repository
COPY . /metrics
WORKDIR /metrics

# Install dependencies
RUN apt-get update \
  && apt-get install -y --no-install-recommends \
     wget gnupg ca-certificates curl git xz-utils python3 build-essential \
  && rm -rf /var/lib/apt/lists/*

# Install Google Chrome
RUN wget -q -O - https://dl-ssl.google.com/linux/linux_signing_key.pub | gpg --dearmor -o /usr/share/keyrings/googlechrome-linux-keyring.gpg \
  && echo "deb [arch=amd64 signed-by=/usr/share/keyrings/googlechrome-linux-keyring.gpg] http://dl.google.com/linux/chrome/deb/ stable main" > /etc/apt/sources.list.d/google-chrome.list \
  && apt-get update \
  && apt-get install -y google-chrome-stable fonts-ipafont-gothic fonts-wqy-zenhei fonts-thai-tlwg fonts-kacst fonts-freefont-ttf libxss1 libx11-xcb1 libxtst6 lsb-release --no-install-recommends \
  && rm -rf /var/lib/apt/lists/*

# Install node modules and build
RUN chmod +x /metrics/source/app/action/index.mjs \
  && npm ci \
  && npm run build

# Execute GitHub action
ENTRYPOINT ["node", "/metrics/source/app/action/index.mjs"]
