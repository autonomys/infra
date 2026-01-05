#!/usr/bin/env bash

# Require bash 4.0+
if ((BASH_VERSINFO[0] < 4)); then
  echo "This script requires Bash 4.0 or higher. Current version: $BASH_VERSION"
  exit 1
fi

# fetch the resources path
RESOURCES_PATH="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SCRIPT_NAME="$(basename "${BASH_SOURCE[0]}")"

# Ensure we have 2 arguments
PROJECT=$1
ACTION=$2

# Allowed projects as a map with their secrets to fetch and store from infisical (requires bash 4+ with associative arrays)
declare -A VALID_PROJECTS
VALID_PROJECTS=(
  ["chronos"]="config.toml,common.auto.tfvars"
  ["dns"]="proxied.json"
  ["devnet"]="config.toml,common.auto.tfvars"
  ["mainnet-domains"]="config.toml,common.auto.tfvars"
  ["mainnet-foundation"]="config.toml,common.auto.tfvars"
  ["mainnet-consensus"]="config.toml,common.auto.tfvars"
  ["chronos-chain-alerter"]="common.auto.tfvars"
  ["mainnet-chain-alerter"]="common.auto.tfvars"
  ["chronos-reward-distributor"]="common.auto.tfvars"
  ["mainnet-reward-distributor"]="common.auto.tfvars"
)

# Allowed actions
VALID_ACTIONS=("init" "upgrade" "plan" "apply" "destroy" "store-secrets" "fetch-secrets" "output")

function show_help() {
  echo "Usage: ${RESOURCES_PATH}/${SCRIPT_NAME} <project> <action>"
  echo "Valid projects:"
  for proj in "${!VALID_PROJECTS[@]}"; do
    echo "  - $proj"
  done
  echo "Valid actions:"
  for act in "${VALID_ACTIONS[@]}"; do
    echo "  - $act"
  done
  echo "Required environment variables:"
  echo "  - INFISICAL_CLIENT_ID"
  echo "  - INFISICAL_CLIENT_SECRET"
  echo "  - INFISICAL_INFRA_PROJECT_ID"
  exit 1
}

# Validate required environment variables
function validate_envs() {
  local missing=0
  if [[ -z "$INFISICAL_CLIENT_ID" ]]; then
    echo "Missing INFISICAL_CLIENT_ID"
    missing=1
  fi
  if [[ -z "$INFISICAL_CLIENT_SECRET" ]]; then
    echo "Missing INFISICAL_CLIENT_SECRET"
    missing=1
  fi
  if [[ -z "$INFISICAL_INFRA_PROJECT_ID" ]]; then
    echo "Missing INFISICAL_INFRA_PROJECT_ID"
    missing=1
  fi

  if [[ $missing -eq 1 ]]; then
    echo
    show_help
  fi
}

function validate_project() {
  local input=$1
  if [[ -n "${VALID_PROJECTS[$input]+set}" ]]; then
    return 0
  fi

  echo "Invalid project: $input"
  show_help
}

function validate_action() {
  local input=$1
  for a in "${VALID_ACTIONS[@]}"; do
    if [[ "$a" == "$input" ]]; then
      return 0
    fi
  done
  echo "Invalid action: $input"
  show_help
}

# store secrets to infisical
function store_secrets() {
  local files="${VALID_PROJECTS[$PROJECT]}"
  echo "Storing secrets for project: $PROJECT"
  local file_args=()
  IFS=',' read -ra file_list <<< "$files"
  for f in "${file_list[@]}"; do
    file_args+=(--file "$f")
  done

  docker run -q --pull always --rm \
    -v "$RESOURCES_PATH/$PROJECT:/data" \
    ghcr.io/autonomys/infra/node-utils:latest \
    infisical-store \
      --client-id "$INFISICAL_CLIENT_ID" \
      --client-secret "$INFISICAL_CLIENT_SECRET" \
      --project-id "$INFISICAL_INFRA_PROJECT_ID" \
      --path "/$PROJECT" \
      "${file_args[@]}"
}

# fetch secrets from infisical
function fetch_secrets() {
  echo "Fetching secrets for project: $PROJECT"

  docker run -q --pull always --rm \
    -v "$RESOURCES_PATH/$PROJECT:/data" \
    ghcr.io/autonomys/infra/node-utils:latest \
    infisical-fetch \
      --client-id "$INFISICAL_CLIENT_ID" \
      --client-secret "$INFISICAL_CLIENT_SECRET" \
      --project-id "$INFISICAL_INFRA_PROJECT_ID" \
      --path "/$PROJECT" 2>&1
}

if [ -z "$PROJECT" ] || [ -z "$ACTION" ]; then
  show_help
fi

# Validate required envs
validate_envs

# Validate project
validate_project "$PROJECT"

validate_action "$ACTION"

case "$ACTION" in
  init)
    echo "Initializing terraform for project: $PROJECT"
    fetch_secrets && \
    terraform -chdir="$RESOURCES_PATH/$PROJECT" init
    ;;
  plan)
    echo "Planning terraform deployment for project: $PROJECT"
    terraform -chdir="$RESOURCES_PATH/$PROJECT" plan -out="$RESOURCES_PATH/$PROJECT/$PROJECT.tfplan"
    ;;
  apply)
    echo "Applying terraform deployment for project: $PROJECT"
    terraform -chdir="$RESOURCES_PATH/$PROJECT" apply "$RESOURCES_PATH/$PROJECT/$PROJECT.tfplan" && \
    store_secrets
    ;;
  upgrade)
    echo "Upgrading terraform providers for project: $PROJECT"
    fetch_secrets && \
    terraform -chdir="$RESOURCES_PATH/$PROJECT" init -upgrade
    ;;
  destroy)
    echo "Destroying terraform deployment for project: $PROJECT"
    terraform -chdir="$RESOURCES_PATH/$PROJECT" destroy && \
    store_secrets
    ;;
  output)
    terraform -chdir="$RESOURCES_PATH/$PROJECT" output
    ;;
  store-secrets)
    store_secrets
    ;;
  fetch-secrets)
    fetch_secrets
    ;;
esac
