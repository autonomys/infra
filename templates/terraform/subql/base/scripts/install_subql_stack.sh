#!/bin/bash

# Exit on any error
set -e

# Check if 'tmux' is installed
if ! command -v tmux &> /dev/null; then
  echo "'tmux' is required but not installed. Please install 'tmux' and try again."
  exit 1
fi

# Check if 'git' is installed
if ! command -v git &> /dev/null; then
  echo "'git' is required but not installed. Please install 'git' and try again."
  exit 1
fi
# Install nvm (Node Version Manager)
export NVM_DIR="$HOME/.nvm"
if [ ! -d "$NVM_DIR" ]; then
  git clone https://github.com/nvm-sh/nvm.git "$NVM_DIR"
  cd "$NVM_DIR" && git checkout `git describe --abbrev=0 --tags`
  cd -
fi

# Load nvm
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"

# Add nvm to .bashrc for future sessions
if ! grep -q 'NVM_DIR' "$HOME/.bashrc"; then
  echo 'export NVM_DIR="$HOME/.nvm"' >> "$HOME/.bashrc"
  echo '[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"' >> "$HOME/.bashrc"
fi

# Source .bashrc to ensure nvm is available in the current session
source "$HOME/.bashrc"

# Install the latest LTS version of Node.js using nvm
nvm install --lts
nvm use --lts

# Add Node.js and npm to PATH and update .bashrc
export PATH="$NVM_DIR/versions/node/$(nvm version)/bin:$PATH"
if ! grep -q 'NVM_DIR/versions/node' "$HOME/.bashrc"; then
  echo 'export PATH="$NVM_DIR/versions/node/$(nvm version)/bin:$PATH"' >> "$HOME/.bashrc"
fi

# Check if 'yarn' is installed
if ! command -v yarn &> /dev/null; then
  echo "'yarn' is not installed. Installing 'yarn'..."
  npm install --global yarn
fi

# Add yarn to PATH and update .bashrc
export PATH="$(yarn global bin):$PATH"
if ! grep -q 'yarn global bin' "$HOME/.bashrc"; then
  echo 'export PATH="$(yarn global bin):$PATH"' >> "$HOME/.bashrc"
fi

source "$HOME/.bashrc"

# Verify installation
node -v
npm -v
yarn -v

# clone the astral repository from Github
git clone https://github.com/autonomys/astral.git
cd astral/indexers

yarn

export $(grep -v '^#' ../.env.prod | xargs) &&
yarn build-dictionary &&
lerna run codegen &&
lerna run build &&
docker compose -p prod-astral-indexers \
  -f ../docker-compose.yml \
  -f ../docker-compose.prod.yml \
  --profile dictionary \
  --profile task \
  --profile taurus \
  up --remove-orphans
