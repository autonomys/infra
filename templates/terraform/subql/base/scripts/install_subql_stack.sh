#!/bin/bash

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

# Install Node.js latest LTS version
## Fetch the latest LTS version of Node.js using NodeSource
curl -fsSL https://deb.nodesource.com/setup_lts.x | sudo -E bash -

# Install Node.js
sudo DEBIAN_FRONTEND=noninteractive apt-get install -y nodejs

# Verify installation
node -v
npm -v

# clone the astral repository from Github
git clone https://github.com/autonomys/astral.git
cd astral

# # Function to run a command in a new tmux session
# run_in_tmux_session() {
#   local session_name="$1"
#   local cmd="$2"

#   tmux new-session -d -s "$session_name" "$cmd"
# }

# # Start indexers stack
# echo "Starting indexers stack..."
# cd indexers || exit 1
# yarn || exit 1
# run_in_tmux_session "indexers_dev" "yarn prod" || exit 1

# # Wait for indexers to sync (adjust sleep duration as needed)
# echo "Waiting for indexers to sync blocks... (sleeping for 30 seconds)"
# sleep 30

# # Run metadata in a new session
# echo "Running yarn metadata in a new session..."
# run_in_tmux_session "indexers_metadata" "cd indexers && yarn metadata && yarn migrate --database-name taurus" || exit 1

# # Start Hasura console in a new session
# echo "Starting Hasura console in a new session..."
# run_in_tmux_session "hasura_console" "cd indexers && yarn console" || exit 1

exit 0
