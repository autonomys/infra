#!/usr/bin/env bash
# Verify that a live Auto Drive staging host matches its spec. Every check only
# reads; none prints secrets or keys or touches service data. The services and
# backend hosts' compose hash checks have Compose read their env files, to hash
# them as the deploy does. The gateway's database checks run gateway-db.sh's
# read-only commands in a one-off container of its backup service.
# Usage: ./validate.sh <role> [ssh-host]
#   role: files-gateway, services, public or private
#   ssh-host defaults to the role's hostname (configure it in ~/.ssh/config, or
#   pass ubuntu@<HOST_IPv4>)
set -euo pipefail

usage() {
  echo "Usage: $0 <role> [ssh-host]   (role: files-gateway, services, public or private)" >&2
  exit 2
}

# copied from main.tf and the role modules' defaults: change them together
ROLE="${1:-}"
case "$ROLE" in
  files-gateway)
    HOSTNAME_WANT="auto-drive-files-gateway-chronos"
    # TCP ports expected to listen beyond loopback and the mesh address
    PUBLIC_TCP_LISTENERS="[22 30333 30343 30433 30443 30543]"
    ;;
  services)
    HOSTNAME_WANT="auto-drive-staging-services"
    PUBLIC_TCP_LISTENERS="[22]"
    ;;
  public)
    HOSTNAME_WANT="auto-drive-staging-public"
    PUBLIC_TCP_LISTENERS="[22 80 443 30343 30443 30543]"
    ;;
  private)
    HOSTNAME_WANT="auto-drive-staging-private"
    PUBLIC_TCP_LISTENERS="[22 80 443]"
    ;;
  *) usage ;;
esac
HOST="${2:-$HOSTNAME_WANT}"

MESH_PORT=51820
MESH_SUBNET=10.77.0.0/24
MESH_HOSTS="services=10.77.0.10 files-gateway=10.77.0.20 public=10.77.0.30 private=10.77.0.40"

DEPLOY_DIR="/home/ubuntu/deploy"
NODE_IMAGE="ghcr.io/autonomys/node:mainnet-2026-jan-20"
GATEWAY_IMAGE="ghcr.io/autonomys/gateway:mainnet-2026-oct-22"
INDEXER_IMAGE="ghcr.io/autonomys/object-mapping-indexer:snapshot-9f2f2c66@sha256:c5eacd88cdbea3705aef0538fc7c4a7a567e3059616ad0d683ecee707798fec5"
RETRIEVER_IMAGE="ghcr.io/autonomys/file-retriever:snapshot-9f2f2c66@sha256:8e5c1dd70789835df442284f0f214f862135caf1fde980b4d86f9c8e93771372"
DAG_INDEXER_IMAGE="ghcr.io/autonomys/dag-indexer:snapshot-4e5990ad@sha256:496343e32a5930aa9aac05de30852d288e50dc556c73351b2860eaf572b673fc"
DAG_BACKUP_IMAGE="postgres:17.9-bookworm@sha256:47f917f7409eacd22fc5dfb1dee634e1b55cf0c01d1a7eb701be2227a03e0641"
# the image's bundled mapping: fe4d7b2's, as built from its source
DAG_DIST_SHA256="6aff7267cefbd9f637372cb05fbacc9becdf543202ca757a57e37d87de4a771c"
DAG_START_BLOCK="1"
# Chronos' launch seeding wrote each DAG node into its remark as hex text, which
# the node maps as the text it is, so no node indexed from those blocks can have
# a mapping; the seeding's last object is at block 29,505
DAG_COVERAGE_FROM="29506"
CHRONOS_GENESIS="0x91912b429ce7bf2975440a0920b46a892fddeeaed6ccc11c93f2d57ad1bd69ab"
# the chain's finalized head trails its best block by five segments, each 10,000
# to 19,000 blocks on Chronos
DAG_LAG_MAX=150000
BACKUP_DIR="/var/backups/auto-drive-gateway"
BACKUP_UNIT="auto-drive-gateway-db-backup"
GATEWAY_MESH_ADDRESS="10.77.0.20"
COMPOSE_PROJECT="file-retriever"
GATEWAY_DIR="$DEPLOY_DIR/auto-drive-gateway"
# gateway-db.sh's read-only commands, in a one-off container of the backup service
GATEWAY_DB="cd $GATEWAY_DIR && sudo docker compose run --rm --no-deps -T gateway-db-backup"
SERVICES_DIR="$DEPLOY_DIR/auto-drive-services"
SERVICES_PROJECT="auto-drive-services"
POSTGRES_IMAGE="postgres:17.9-bookworm"
RABBITMQ_IMAGE="rabbitmq:3.13.7-management"
LOKI_URL="https://logging.subspace.network/loki/api/v1/push"
BACKEND_DIR="$DEPLOY_DIR/auto-drive"
BACKEND_PROJECT="auto-drive"
BACKEND_IMAGE="ghcr.io/autonomys/auto-drive-backend:99e753be@sha256:78288688bf82fd87101eea25bed789410ef4ade33085978432dc91df0d7d80d2"
HASURA_IMAGE="hasura/graphql-engine:v2.40.0.cli-migrations-v3@sha256:68b16a019e4f6f3136fb09ef26a934c718e3ff74eab76d52244abccb8fd80b55"
PUBLIC_APP_HOST="public.staging.auto-drive.autonomys.xyz"
PUBLIC_CERT_NAMES="public.staging.auto-drive.autonomys.xyz s3.staging.auto-drive.autonomys.xyz"
PUBLIC_SERVICES="hasura=6565 backend-download-api=3000 backend-download-worker=3030"
PRIVATE_APP_HOST="chronos.auto-drive.autonomys.xyz"
AUTH_HOST="auth.staging.auto-drive.autonomys.xyz"
PRIVATE_CERT_NAMES="$PRIVATE_APP_HOST $AUTH_HOST"
PRIVATE_SERVICES="hasura=6565 backend-api=3000 backend-worker=3030 backend-publish-worker=3031"
# the only sources the private host's 80 and 443 are open to: Cloudflare's ranges
PRIVATE_INGRESS_RANGES="173.245.48.0/20 103.21.244.0/22 103.22.200.0/22 103.31.4.0/22 141.101.64.0/18 108.162.192.0/18 190.93.240.0/20 188.114.96.0/20 197.234.240.0/22 198.41.128.0/17 162.158.0.0/15 104.16.0.0/13 104.24.0.0/14 172.64.0.0/13 131.0.72.0/22"
AUTH_DIR="$DEPLOY_DIR/auto-drive-auth"
AUTH_PROJECT="auto-drive-auth"
AUTH_IMAGE="ghcr.io/autonomys/auto-drive-auth:snapshot-6554f564@sha256:c689550a14ffa2815f81164283a388133548b1da3742628e30fee8d9a7771ffd"
AUTH_PORT=3040
SERVICES_MESH_ADDRESS="10.77.0.10"
FARMER_DIR="$DEPLOY_DIR/subspace-farmer"
FARMER_PROJECT="subspace-farmer"
FARMER_NODE_IMAGE="ghcr.io/autonomys/node:mainnet-2026-oct-22@sha256:76cf36d40ecbc382edd072567f3a7b2c631530fd81027f29095877ad3509a24f"
FARMER_IMAGE="ghcr.io/autonomys/farmer:mainnet-2026-oct-22@sha256:d140be610587c679a031b69df033be95adb777e425720e7ccefe34a686eff543"
FARMER_SYNC="full"
# the node's P2P and DSN ports, then the farmer's
FARMER_NODE_PORT=30343
FARMER_NODE_DSN_PORT=30443
FARMER_PORT=30543
FARM_SIZE="1GiB"
FARM_BYTES=1073741824
REWARD_ADDRESS="suexrxoBh96UgcCyKXVMTEUhR8LtJozJssVT8Wrzs16bjBSn6"
# what a backend role's checks look at
case "$ROLE" in
  public)
    BACKEND_SERVICES="$PUBLIC_SERVICES"
    BACKEND_FILES="docker-compose.yml docker-compose.log-cap.yml docker-compose.workers-env.yml .env"
    API_SERVICE="backend-download-api"
    APP_HOST="$PUBLIC_APP_HOST"
    CERT_NAMES="$PUBLIC_CERT_NAMES"
    ;;
  private)
    BACKEND_SERVICES="$PRIVATE_SERVICES"
    BACKEND_FILES="docker-compose.yml docker-compose.log-cap.yml docker-compose.workers-env.yml .env workers.env"
    API_SERVICE="backend-api"
    APP_HOST="$PRIVATE_APP_HOST"
    CERT_NAMES="$PRIVATE_CERT_NAMES"
    ;;
esac
ERRORS=0
PASS=0

GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m'

pass() {
  echo -e "  ${GREEN}PASS${NC}: $1"
  PASS=$((PASS + 1))
}

fail() {
  echo -e "  ${RED}FAIL${NC}: $1"
  echo "        expected: '$2'"
  echo "        got:      '$3'"
  ERRORS=$((ERRORS + 1))
}

# Exact unless mode is "contains", which is only for output that carries a
# version or other text around the value: a failed state's name often contains
# the healthy one (inactive, unhealthy, raid10).
report() {
  local desc="$1" result="$2" expected="$3" mode="${4:-exact}"
  if { [[ "$mode" == exact ]] && [[ "$result" == "$expected" ]]; } \
    || { [[ "$mode" == contains ]] && [[ "$result" == *"$expected"* ]]; }; then
    pass "$desc"
  else
    fail "$desc" "$expected" "$result"
  fi
}

# runs on the host; a command that exits non-zero fails whatever it printed
check() {
  local out rc=0
  out="$(ssh -o ConnectTimeout=5 "$HOST" "$2" 2>/dev/null)" || rc=$?
  if [[ $rc -ne 0 ]]; then
    fail "$1" "$3" "exit $rc: $out"
  else
    report "$1" "$out" "$3" "${4:-exact}"
  fi
}

NODE="\$(sudo docker ps -q --filter label=com.docker.compose.project=$COMPOSE_PROJECT --filter label=com.docker.compose.service=subspace-node)"
RPC="curl -s -H 'Content-Type: application/json' http://127.0.0.1:9944"
# the running container of a gateway service, looked up on the host
container() { echo "\$(sudo docker ps -q --filter label=com.docker.compose.project=$COMPOSE_PROJECT --filter label=com.docker.compose.service=$1)"; }
PG="\$(sudo docker ps -q --filter label=com.docker.compose.project=$SERVICES_PROJECT --filter label=com.docker.compose.service=postgres)"
RMQ="\$(sudo docker ps -q --filter label=com.docker.compose.project=$SERVICES_PROJECT --filter label=com.docker.compose.service=rabbitmq)"
PSQL="sudo docker exec $PG psql -X -At -U postgres -d postgres -c"

echo "=== Validating $HOST ==="
echo ""

echo "[Host]"
check "Hostname" "hostname" "$HOSTNAME_WANT"
# the bootstrap sets UTC; tzdata upgrades repoint /etc/localtime at its
# canonical name, Etc/UTC
check "Timezone" "timedatectl show -p Timezone --value | sed 's|^Etc/UTC\$|UTC|'" "UTC"
check "Ubuntu" "lsb_release -is" "Ubuntu"
check "Booted via legacy BIOS" "test -d /sys/firmware/efi && echo uefi || echo bios" "bios"

echo ""
echo "[Storage]"
for mount in / /boot; do
  check "$mount on RAID 1" \
    "sudo mdadm --detail \$(findmnt -no SOURCE $mount) | awk -F': ' '/Raid Level/ {print \$2}'" "raid1"
  check "$mount mirror in sync with both members active" \
    "d=\$(sudo mdadm --detail \$(findmnt -no SOURCE $mount)); echo \"\$d\" | grep -qE '^ *State : (clean|active)(, checking)? *$' && echo \"\$d\" | grep -q 'Active Devices : 2' && echo synced || echo \"out of sync: \$(echo \"\$d\" | grep -E 'State :|Active Devices :' | tr -s ' ' | tr '\\n' ';')\"" \
    "synced"
done
check "Swap on RAID 1" \
  "s=\$(swapon --noheadings --show=NAME | head -1); sudo mdadm --detail \$s | awk -F': ' '/Raid Level/ {print \$2}'" "raid1"
check "Swap mirror in sync with both members active" \
  "d=\$(sudo mdadm --detail \$(swapon --noheadings --show=NAME | head -1)); echo \"\$d\" | grep -qE '^ *State : (clean|active)(, checking)? *$' && echo \"\$d\" | grep -q 'Active Devices : 2' && echo synced || echo \"out of sync: \$(echo \"\$d\" | grep -E 'State :|Active Devices :' | tr -s ' ' | tr '\\n' ';')\"" \
  "synced"
check "No array degraded or resyncing" \
  "grep -E '\\[[U_]+\\]' /proc/mdstat | grep -q _ && echo degraded || { grep -qE 'resync|recovery' /proc/mdstat && echo resyncing || echo healthy; }" \
  "healthy"
check "No RAID 0 anywhere" "grep -cE '^md[0-9]+ : active raid0' /proc/mdstat || true" "0"

echo ""
echo "[Bootloader]"
BOOT_DISKS="for m in /sys/block/\$(basename \$(readlink -f \$(findmnt -no SOURCE /boot)))/slaves/*; do echo /dev/\$(lsblk -dno PKNAME /dev/\$(basename \$m)); done"
check "Both /boot disks carry GRUB boot code" \
  "n=0; for d in \$($BOOT_DISKS); do sudo dd if=\$d bs=512 count=1 status=none | grep -aq GRUB && n=\$((n+1)); done; echo \"\$n disks with boot code\"" \
  "2 disks with boot code"
check "BIOS GRUB package installed" "dpkg-query -W -f='\${Status}' grub-pc" "install ok installed"
check "UEFI GRUB package absent" \
  "dpkg-query -W -f='\${Status}' grub-efi-amd64 2>/dev/null | grep -q 'install ok installed' && echo present || echo absent" \
  "absent"
check "GRUB updates reinstall to both disks" \
  "sudo debconf-show grub-pc | sed -n 's/.*grub-pc\\/install_devices: //p' | tr ',' '\\n' | grep -c /dev/" "2"

echo ""
echo "[SSH Hardening]"
check "PermitRootLogin disabled" \
  "sudo sshd -T 2>/dev/null | grep -i '^permitrootlogin '" "permitrootlogin no"
check "PasswordAuthentication disabled" \
  "sudo sshd -T 2>/dev/null | grep -i '^passwordauthentication '" "passwordauthentication no"
check "KbdInteractiveAuthentication disabled" \
  "sudo sshd -T 2>/dev/null | grep -i '^kbdinteractiveauthentication '" "kbdinteractiveauthentication no"
check "Deploy user has passwordless sudo" "sudo -n true && echo ok" "ok"

echo ""
echo "[Firewall]"
check "UFW active" "sudo ufw status | head -1" "Status: active"
check "UFW SSH rule" "sudo ufw status | grep -cE '^22/tcp +ALLOW +Anywhere +# ssh'" "1"
if [[ $ROLE == files-gateway ]]; then
  check "UFW node P2P rules" \
    "sudo ufw status | grep -cE '^(30333|30433)/tcp +ALLOW .*# role-port'" "2"
fi
if [[ $ROLE == public ]]; then
  check "UFW opens 80 and 443" \
    "sudo ufw status | grep -cE '^(80|443)/tcp +ALLOW +Anywhere +# role-port'" "2"
elif [[ $ROLE == private ]]; then
  for port in 80 443; do
    check "UFW opens $port to the ingress ranges and nobody else" \
      "sudo ufw status | awk '\$1 == \"$port/tcp\" || \$1 == \"$port\" {print \$3}' | sort | paste -sd ' ' -" \
      "$(tr ' ' '\n' <<< "$PRIVATE_INGRESS_RANGES" | sort | paste -sd ' ' -)"
  done
else
  check "80/443 closed" \
    "sudo ufw status | awk '{print \$1}' | grep -qE '(^|,)(80|443)(,|/)' && echo open || echo closed" "closed"
fi

echo ""
echo "[Services]"
check "fail2ban running" "systemctl is-active fail2ban" "active"
check "unattended-upgrades active" "systemctl is-active unattended-upgrades" "active"
check "fail2ban sshd jail" "sudo grep '^maxretry' /etc/fail2ban/jail.local" "maxretry = 5"
check "Auto-reboot disabled" \
  "grep Automatic-Reboot /etc/apt/apt.conf.d/50unattended-upgrades-local" 'Unattended-Upgrade::Automatic-Reboot "false";'
check "Background apt timers resumed after setup" \
  "[ \"\$(systemctl is-active apt-daily.timer apt-daily-upgrade.timer | sort -u)\" = active ] && echo resumed || echo paused" \
  "resumed"

echo ""
echo "[Docker]"
check "Docker installed" "docker --version" "Docker version" contains
check "Compose plugin installed" "docker compose version" "Docker Compose version" contains
check "Loki log driver plugin enabled" "sudo docker plugin inspect -f '{{.Enabled}}' loki:latest" "true"
check "ubuntu in docker group" "id -nG ubuntu | tr ' ' '\\n' | grep -cx docker" "1"
check "journald capped" "grep '^SystemMaxUse' /etc/systemd/journald.conf.d/size.conf" "SystemMaxUse=200M"

echo ""
echo "[Mesh]"
SELF_ADDRESS=""
PEER_ADDRESSES=""
for member in $MESH_HOSTS; do
  if [[ ${member%%=*} == "$ROLE" ]]; then
    SELF_ADDRESS="${member#*=}"
  else
    PEER_ADDRESSES="$PEER_ADDRESSES ${member#*=}"
  fi
done
PEER_ADDRESSES="${PEER_ADDRESSES# }"
PEER_COUNT=$(wc -w <<< "$PEER_ADDRESSES" | tr -d ' ')
check "wg-quick@wg0 enabled" "systemctl is-enabled wg-quick@wg0" "enabled"
check "wg-quick@wg0 active" "systemctl is-active wg-quick@wg0" "active"
check "wg0 address" "ip -4 -o addr show dev wg0 | awk '{print \$4}'" "$SELF_ADDRESS/${MESH_SUBNET#*/}"
check "wg0 listen port" "sudo wg show wg0 listen-port" "$MESH_PORT"
check "WireGuard listening on UDP $MESH_PORT" \
  "sudo ss -Huln 'sport = :$MESH_PORT' | awk '{print \$4}' | sort -u | paste -sd ' ' -" "0.0.0.0:$MESH_PORT [::]:$MESH_PORT"
check "wg0 has its key loaded" "sudo wg show wg0 public-key | grep -cvx '(none)' || true" "1"
check "Private key file root-only" "sudo stat -c '%a %U' /etc/wireguard/wg0.key" "600 root"
check "wg0.conf root-only" "sudo stat -c '%a %U' /etc/wireguard/wg0.conf" "600 root"
check "Peers are the other mesh members" \
  "sudo wg show wg0 allowed-ips | awk '{print \$2}' | sort | paste -sd ' ' -" \
  "$(for a in $PEER_ADDRESSES; do echo "$a/32"; done | sort | paste -sd ' ' -)"
for peer in $PEER_ADDRESSES; do
  check "Peer $peer answers over the mesh" \
    "ping -c 3 -W 2 -I wg0 $peer >/dev/null && echo reachable" "reachable"
done
check "UFW opens $MESH_PORT/udp to each peer only" \
  "sudo ufw status | grep -cE '^$MESH_PORT/udp +ALLOW +[0-9.]+ +# mesh-peer' || true" "$PEER_COUNT"
check "UFW does not open $MESH_PORT/udp to anywhere" \
  "sudo ufw status | grep -cE '^$MESH_PORT/udp.* Anywhere' || true" "0"
check "Docker wants wg0" \
  "systemctl show docker -p Wants --value | tr ' ' '\\n' | grep -cx wg-quick@wg0.service" "1"
check "Docker starts after wg0" \
  "systemctl show docker -p After --value | tr ' ' '\\n' | grep -cx wg-quick@wg0.service" "1"
check "Containers can bind the mesh address before wg0 is up" "cat /proc/sys/net/ipv4/ip_nonlocal_bind" "1"
check "Mesh address guarded against other interfaces" \
  "sudo iptables -S DOCKER-USER | grep -cxF -- '-A DOCKER-USER ! -i wg0 -m conntrack --ctorigdst $SELF_ADDRESS --ctdir ORIGINAL -j DROP'" "1"
check "Forwarded traffic meets DOCKER-USER first" "sudo iptables -S FORWARD | sed -n 2p" "-A FORWARD -j DOCKER-USER"
# Not a pass/fail, and it only holds after a reboot since the host joined the
# mesh. It reads each unit's first start this boot from the journal (systemd's
# unit-started message), which restarting wg0 or docker in place doesn't change.
boot_order() {
  ssh -o ConnectTimeout=5 "$HOST" bash -s 2>/dev/null <<'EOF' || echo unknown
first="$(sudo journalctl -b -q -o short-monotonic | head -1 | tr -d '[' | awk '{print int($1)}')"
if [ "${first:-999}" -gt 5 ]; then
  echo "unknown, the start of this boot has left the journal"
  exit 0
fi
case "$(sudo journalctl -b -q -o cat --output-fields=UNIT MESSAGE_ID=39f53479d3a045ac8e11786248231fbf UNIT=wg-quick@wg0.service UNIT=docker.service | head -1)" in
  wg-quick@wg0.service) echo "wg0 came up before docker" ;;
  docker.service) echo "docker started before wg0 (expected until the first reboot after joining the mesh)" ;;
  *) echo "unknown" ;;
esac
EOF
}
echo "  this boot: $(boot_order)"

echo ""
echo "[Ports]"
# every listener bound beyond loopback and the mesh address, as port numbers
SELF_ADDRESS_RE="${SELF_ADDRESS//./\\.}"
PUBLIC_LISTENERS="sudo ss -Htlnp | awk '\$4 !~ /^(127\\.|\\[::1\\]|\\[::ffff:127\\.|$SELF_ADDRESS_RE:)/ {n=split(\$4,a,\":\"); print a[n]}' | sort -un | tr '\\n' ' ' | sed 's/^/[/; s/ \$/]/'"
check "Only the role's TCP ports listen beyond loopback and the mesh" "$PUBLIC_LISTENERS" "$PUBLIC_TCP_LISTENERS"
check "At least 2 GB free under /var/lib" \
  "[ \$(df --output=avail -B1G /var/lib | tail -1) -ge 2 ] && echo ok" "ok"

files_gateway_checks() {
  local first second
  echo ""
  echo "[Gateway deploy]"
  check "Compose files, scripts and env files in place" \
    "cd $GATEWAY_DIR && stat -c '%n %a %U' docker-compose.yml docker-compose.mesh.yml docker-compose.log-cap.yml docker-compose.dag-indexer.yml dag-indexer-start-guard.js gateway-db.sh .env file-retriever.env object-mapping-indexer.env gateway-db.env | paste -sd ' ' -" \
    "docker-compose.yml 644 ubuntu docker-compose.mesh.yml 644 ubuntu docker-compose.log-cap.yml 644 ubuntu docker-compose.dag-indexer.yml 644 ubuntu dag-indexer-start-guard.js 644 ubuntu gateway-db.sh 644 ubuntu .env 600 ubuntu file-retriever.env 600 ubuntu object-mapping-indexer.env 600 ubuntu gateway-db.env 600 ubuntu"
  # the running node's config hash is the files': no change is waiting on a restart
  check "Node matches the compose files" \
    "cd $GATEWAY_DIR && [ \"\$(sudo docker compose config --hash subspace-node | awk '{print \$2}')\" = \"\$(sudo docker inspect -f '{{index .Config.Labels \"com.docker.compose.config-hash\"}}' $NODE)\" ] && echo match || echo differs" \
    "match"
  check "Node container running" "sudo docker inspect -f '{{.State.Status}}' $NODE" "running"
  check "Node container healthy" "sudo docker inspect -f '{{.State.Health.Status}}' $NODE" "healthy"
  check "Node image" "sudo docker inspect -f '{{.Config.Image}}' $NODE" "$NODE_IMAGE"
  check "Node on Chronos" "sudo docker inspect -f '{{json .Args}}' $NODE" '"--chain","chronos"' contains
  check "Node archives blocks and state" \
    "a=\$(sudo docker inspect -f '{{json .Args}}' $NODE); echo \"\$a\" | grep -qF '\"--blocks-pruning\",\"archive\"' && echo \"\$a\" | grep -qF '\"--state-pruning\",\"archive\"' && echo archive" \
    "archive"
  check "Node creates object mappings" "sudo docker inspect -f '{{json .Args}}' $NODE" '"--create-object-mappings","yes"' contains
  check "Node logs ship through the loki driver" \
    "sudo docker inspect -f '{{.HostConfig.LogConfig.Type}} {{index .HostConfig.LogConfig.Config \"loki-url\"}}' $NODE" \
    "loki https://logging.subspace.network/loki/api/v1/push"
  check "Node's local log copy capped" \
    "sudo docker inspect -f '{{index .HostConfig.LogConfig.Config \"max-size\"}} {{index .HostConfig.LogConfig.Config \"max-file\"}}' $NODE" \
    "10m 3"
  check "No loki driver push errors in the last hour" \
    "sudo journalctl -u docker --since '-1h' --no-pager | grep -ci 'error sending batch' || true" "0"
  check "Node RPC answers on loopback" \
    "$RPC -d '{\"id\":1,\"jsonrpc\":\"2.0\",\"method\":\"system_chain\"}'" '"result":"Autonomys Chronos Testnet"' contains
  check "Node RPC on loopback only" \
    "sudo ss -Htln 'sport = :9944' | awk '{print \$4}' | sort -u | paste -sd ' ' -" "127.0.0.1:9944"
  check "Node has peers" \
    "$RPC -d '{\"id\":1,\"jsonrpc\":\"2.0\",\"method\":\"system_health\"}' | grep -o '\"peers\":[0-9]*' | grep -qv '\"peers\":0\$' && echo peered" \
    "peered"

  echo ""
  echo "[Gateway apps]"
  for service in subspace-rpc-gateway object-mapping-app file-retriever; do
    check "$service running" "sudo docker inspect -f '{{.State.Status}}' $(container "$service")" "running"
  done
  check "RPC gateway image" "sudo docker inspect -f '{{.Config.Image}}' $(container subspace-rpc-gateway)" "$GATEWAY_IMAGE"
  check "Object-mapping indexer image" "sudo docker inspect -f '{{.Config.Image}}' $(container object-mapping-app)" "$INDEXER_IMAGE"
  check "File retriever image" "sudo docker inspect -f '{{.Config.Image}}' $(container file-retriever)" "$RETRIEVER_IMAGE"
  for service in object-mapping-indexer-migrate file-retriever-migrate gateway-db-backup; do
    check "$service finished cleanly" \
      "sudo docker inspect -f '{{.State.Status}} {{.State.ExitCode}}' \$(sudo docker ps -aq --filter label=com.docker.compose.project=$COMPOSE_PROJECT --filter label=com.docker.compose.service=$service --filter label=com.docker.compose.oneoff=False)" \
      "exited 0"
  done
  check "Apps log through the loki driver, capped" \
    "for c in $(container subspace-rpc-gateway) $(container object-mapping-app) $(container file-retriever) $(container dag-indexer); do sudo docker inspect -f '{{.HostConfig.LogConfig.Type}} {{index .HostConfig.LogConfig.Config \"max-size\"}} {{index .HostConfig.LogConfig.Config \"max-file\"}}' \$c; done | sort -u" \
    "loki 10m 3"
  check "RPC gateway on loopback only" \
    "sudo ss -Htln 'sport = :9955' | awk '{print \$4}' | sort -u | paste -sd ' ' -" "127.0.0.1:9955"
  check "Object-mapping indexer on loopback and the mesh only" \
    "sudo ss -Htln 'sport = :3000' | awk '{print \$4}' | sort -u | paste -sd ' ' -" "$GATEWAY_MESH_ADDRESS:3000 127.0.0.1:3000"
  check "File retriever on loopback and the mesh only" \
    "sudo ss -Htln 'sport = :8090' | awk '{print \$4}' | sort -u | paste -sd ' ' -" "$GATEWAY_MESH_ADDRESS:8090 127.0.0.1:8090"
  check "Object-mapping indexer healthy" "curl -s -o /dev/null -w '%{http_code}' http://127.0.0.1:3000/health" "200"
  check "File retriever healthy" "curl -s -o /dev/null -w '%{http_code}' http://127.0.0.1:8090/health" "200"

  echo ""
  echo "[Sync progress]"
  # not a pass/fail: two samples a minute apart show whether the node and the
  # DAG index are moving
  SYNC_STATE="$RPC -d '{\"id\":1,\"jsonrpc\":\"2.0\",\"method\":\"system_syncState\"}'"
  DAG_PROGRESS="$GATEWAY_DB meta lastProcessedHeight"
  first="$(ssh -o ConnectTimeout=5 "$HOST" "$SYNC_STATE" 2>/dev/null || true)"
  dag_first="$(ssh -o ConnectTimeout=5 "$HOST" "$DAG_PROGRESS" 2>/dev/null || true)"
  echo "  now:       $first, DAG index at ${dag_first:-none}"
  sleep 60
  second="$(ssh -o ConnectTimeout=5 "$HOST" "$SYNC_STATE" 2>/dev/null || true)"
  dag_second="$(ssh -o ConnectTimeout=5 "$HOST" "$DAG_PROGRESS" 2>/dev/null || true)"
  echo "  +60s:      $second, DAG index at ${dag_second:-none}"
  current() { grep -o '"currentBlock":[0-9]*' <<< "$1" | cut -d: -f2; }
  importing=false
  if [[ -n "$(current "$first")" && -n "$(current "$second")" && "$(current "$second")" -gt "$(current "$first")" ]]; then
    importing=true
    report "Node importing blocks" "advancing" "advancing"
  else
    report "Node importing blocks" "not advancing" "advancing"
  fi

  dag_indexer_checks "$dag_first" "$dag_second" "$importing"
  gateway_backup_checks
}

dag_indexer_checks() {
  local dag_first="$1" dag_second="$2" importing="$3" c target health
  # stopped or restarting too, so its state shows
  c="\$(sudo docker ps -aq --filter label=com.docker.compose.project=$COMPOSE_PROJECT --filter label=com.docker.compose.service=dag-indexer)"
  echo ""
  echo "[DAG indexer]"
  # a start the guard refused shows in Loki, and as the database behind the
  # floor in the backup checks; the local log copy may not hold it
  check "dag-indexer running" \
    "sudo docker inspect -f '{{.State.Status}}' $c" "running"
  check "dag-indexer healthy (/ready)" "sudo docker inspect -f '{{.State.Health.Status}}' $c" "healthy"
  check "dag-indexer matches the compose files" \
    "cd $GATEWAY_DIR && [ \"\$(sudo docker compose config --hash dag-indexer | awk '{print \$2}')\" = \"\$(sudo docker inspect -f '{{index .Config.Labels \"com.docker.compose.config-hash\"}}' $c)\" ] && echo match || echo differs" \
    "match"
  check "dag-indexer image" "sudo docker inspect -f '{{.Config.Image}}' $c" "$DAG_INDEXER_IMAGE"
  check "dag-indexer manifest, endpoint and flags" "sudo docker inspect -f '{{json .Args}}' $c" \
    '"-f","/app/project.chronos.yaml","--network-endpoint=ws://subspace-node:9944/ws","--db-schema=dag-indexer","--workers=1","--unsafe","--batch-size=125","--scale-batch-size","--unfinalized-blocks=true","--disable-historical=false","--finalized-depth=100"' contains
  check "Backup service image" \
    "sudo docker inspect -f '{{.Config.Image}}' \$(sudo docker ps -aq --filter label=com.docker.compose.project=$COMPOSE_PROJECT --filter label=com.docker.compose.service=gateway-db-backup --filter label=com.docker.compose.oneoff=False)" \
    "$DAG_BACKUP_IMAGE"
  check "dag-indexer on loopback only" \
    "sudo ss -Htln 'sport = :30001' | awk '{print \$4}' | sort -u | paste -sd ' ' -" "127.0.0.1:30001"
  check "Running mapping is the pinned bundle" \
    "sudo docker exec $c sha256sum /app/dist/index.js | cut -d' ' -f1" "$DAG_DIST_SHA256"
  check "Manifest is Chronos' from block $DAG_START_BLOCK" \
    "sudo docker exec $c grep -cE \"^ *(chainId: '$CHRONOS_GENESIS'|startBlock: $DAG_START_BLOCK)\$\" /app/project.chronos.yaml" "2"
  check "dag-indexer on Chronos (/meta genesisHash)" \
    "curl -s -m 5 http://127.0.0.1:30001/meta | python3 -c 'import json, sys; print(json.load(sys.stdin).get(\"genesisHash\"))'" \
    "$CHRONOS_GENESIS"
  target="$(ssh -o ConnectTimeout=5 "$HOST" "curl -s -m 5 http://127.0.0.1:30001/meta | python3 -c 'import json, sys; m = json.load(sys.stdin); print(m[\"targetHeight\"], m[\"bestHeight\"])'" 2>/dev/null || true)"
  if [[ -n "$target" ]] && (( ${target#* } - ${target% *} <= DAG_LAG_MAX )); then
    report "Target within the finalized head's lag of the best block" "within $DAG_LAG_MAX" "within $DAG_LAG_MAX"
  else
    report "Target within the finalized head's lag of the best block" "target and best: ${target:-unknown}" "within $DAG_LAG_MAX"
  fi
  health="$(ssh -o ConnectTimeout=5 "$HOST" "curl -s -m 5 -o /dev/null -w '%{http_code}' http://127.0.0.1:30001/health" 2>/dev/null || true)"
  report "dag-indexer's endpoint healthy (/health)" "$health" "200"
  if [[ "$health" != 200 && "$importing" == false ]]; then
    echo "        the node isn't importing blocks, as while it re-archives, so /health fails until it does"
  fi
  # caught up means at the target, which moves a segment at a time
  if [[ -n "$dag_first" && -n "$dag_second" ]] && { (( dag_second > dag_first )) || [[ -n "$target" && "$dag_second" -ge $(( ${target% *} - 5 )) ]]; }; then
    report "DAG index advancing or caught up" "yes" "yes"
  else
    report "DAG index advancing or caught up" "at ${dag_second:-none} after ${dag_first:-none}, target ${target% *}" "yes"
  fi
  check "Index started at block $DAG_START_BLOCK" "$GATEWAY_DB meta startHeight" "$DAG_START_BLOCK"
  check "Schema records the image's schema.graphql" \
    "h=\$(sudo docker exec $c sha256sum /app/schema.graphql | cut -d' ' -f1); r=\$($GATEWAY_DB schema-hash); [ \"\$h\" = \"\$r\" ] && echo match || echo \"recorded '\$r', image \$h\"" \
    "match"
  check "Every node indexed from block $DAG_COVERAGE_FROM has its object mapping" "$GATEWAY_DB coverage $DAG_COVERAGE_FROM" "0"
}

gateway_backup_checks() {
  local newest="sudo ls $BACKUP_DIR | grep -E '^gateway-[0-9TZ]+\\.dump\$' | sort | tail -1"
  echo ""
  echo "[Gateway database backups]"
  check "Backup timer enabled and active" \
    "echo \$(systemctl is-enabled $BACKUP_UNIT.timer) \$(systemctl is-active $BACKUP_UNIT.timer)" "enabled active"
  check "Last timed backup succeeded" "systemctl show $BACKUP_UNIT.service -p Result --value" "success"
  check "Backup directories root-only, floor readable" \
    "sudo stat -c '%a %U' $BACKUP_DIR $BACKUP_DIR/floor $BACKUP_DIR/floor/progress-floor | paste -sd ' ' -" \
    "700 root 755 root 644 root"
  check "1 to 7 dumps kept" \
    "n=\$(sudo ls $BACKUP_DIR | grep -cE '^gateway-[0-9TZ]+\\.dump\$'); [ \$n -ge 1 ] && [ \$n -le 7 ] && echo ok || echo \"\$n dumps\"" "ok"
  check "Newest dump under 26 hours old" \
    "n=\$($newest); if [ -z \"\$n\" ]; then echo 'no dump'; else age=\$(( (\$(date +%s) - \$(sudo stat -c %Y $BACKUP_DIR/\$n)) / 3600 )); [ \$age -lt 26 ] && echo fresh || echo \"\$n is \${age}h old\"; fi" \
    "fresh"
  check "No dump set aside as behind the floor" \
    "n=\$(sudo ls $BACKUP_DIR | grep -c '\\.dump\\.suspect\$' || true); [ \"\$n\" = 0 ] && echo none || echo \"\$n: \$(sudo sh -c 'cat $BACKUP_DIR/*.progress.suspect' | tr '\\n' ' ')\"" \
    "none"
  check "Floor is the newest dump's progress" \
    "n=\$($newest); [ \"\$(sudo grep -E '^(dag|mapping)_height=' $BACKUP_DIR/floor/progress-floor)\" = \"\$(sudo grep -E '^(dag|mapping)_height=' $BACKUP_DIR/\${n%.dump}.progress)\" ] && echo match || echo differs" \
    "match"
  check "Newest dump readable by pg_restore" \
    "n=\$($newest); cd $GATEWAY_DIR && sudo docker compose run --rm --no-deps -T --entrypoint pg_restore gateway-db-backup --list /backups/\$n > /dev/null && echo readable" \
    "readable"
  check "Database at or above the floor" "$GATEWAY_DB check-progress" "at or above the floor"
}

services_checks() {
  echo ""
  echo "[Services deploy]"
  check "Compose files, .env and env files in place" \
    "cd $SERVICES_DIR && stat -c '%n %a %U' docker-compose.yml rabbitmq.conf .env postgres.env rabbitmq.env | paste -sd ' ' -" \
    "docker-compose.yml 644 ubuntu rabbitmq.conf 644 ubuntu .env 600 ubuntu postgres.env 600 ubuntu rabbitmq.env 600 ubuntu"
  # each running container's config hash is the files': no change is waiting on a restart
  check "Postgres matches the compose files" \
    "cd $SERVICES_DIR && [ \"\$(sudo docker compose config --hash postgres | awk '{print \$2}')\" = \"\$(sudo docker inspect -f '{{index .Config.Labels \"com.docker.compose.config-hash\"}}' $PG)\" ] && echo match || echo differs" \
    "match"
  check "RabbitMQ matches the compose files" \
    "cd $SERVICES_DIR && [ \"\$(sudo docker compose config --hash rabbitmq | awk '{print \$2}')\" = \"\$(sudo docker inspect -f '{{index .Config.Labels \"com.docker.compose.config-hash\"}}' $RMQ)\" ] && echo match || echo differs" \
    "match"
  check "Postgres healthy" "sudo docker inspect -f '{{.State.Health.Status}}' $PG" "healthy"
  check "Postgres image" "sudo docker inspect -f '{{.Config.Image}}' $PG" "$POSTGRES_IMAGE"
  check "Postgres restarts unless stopped" "sudo docker inspect -f '{{.HostConfig.RestartPolicy.Name}}' $PG" "unless-stopped"
  check "Postgres given 2 minutes to stop" "sudo docker inspect -f '{{.Config.StopTimeout}}' $PG" "120"
  check "Postgres memory limit 32 GiB, shm 2 GiB" \
    "sudo docker inspect -f '{{.HostConfig.Memory}} {{.HostConfig.ShmSize}}' $PG" "34359738368 2147483648"
  check "Postgres data in its named volume" \
    "sudo docker inspect -f '{{range .Mounts}}{{if eq .Destination \"/var/lib/postgresql/data\"}}{{.Type}} {{.Name}}{{end}}{{end}}' $PG" \
    "volume ${SERVICES_PROJECT}_postgres-data"
  check "Postgres logs ship through the loki driver" \
    "sudo docker inspect -f '{{.HostConfig.LogConfig.Type}} {{index .HostConfig.LogConfig.Config \"loki-url\"}}' $PG" \
    "loki $LOKI_URL"
  check "Postgres's local log copy capped" \
    "sudo docker inspect -f '{{index .HostConfig.LogConfig.Config \"max-size\"}} {{index .HostConfig.LogConfig.Config \"max-file\"}}' $PG" \
    "10m 3"
  check "Postgres on loopback and the mesh only" \
    "sudo ss -Htln 'sport = :5432' | awk '{print \$4}' | sort -u | paste -sd ' ' -" "$SELF_ADDRESS:5432 127.0.0.1:5432"
  check "Postgres version" "$PSQL 'SHOW server_version'" "17.9" contains
  check "Databases present" \
    "$PSQL \"SELECT string_agg(datname, ' ' ORDER BY datname) FROM pg_database WHERE datname IN ('auth', 'gateway', 'postgres')\"" \
    "auth gateway postgres"
  check "Postgres tuning applied" \
    "$PSQL \"SELECT current_setting('shared_buffers') || ' ' || current_setting('effective_cache_size') || ' ' || current_setting('max_connections')\"" \
    "8GB 24GB 300"

  check "RabbitMQ healthy" "sudo docker inspect -f '{{.State.Health.Status}}' $RMQ" "healthy"
  check "RabbitMQ image" "sudo docker inspect -f '{{.Config.Image}}' $RMQ" "$RABBITMQ_IMAGE"
  check "RabbitMQ restarts unless stopped" "sudo docker inspect -f '{{.HostConfig.RestartPolicy.Name}}' $RMQ" "unless-stopped"
  check "RabbitMQ given 2 minutes to stop" "sudo docker inspect -f '{{.Config.StopTimeout}}' $RMQ" "120"
  check "RabbitMQ memory limit 4 GiB" "sudo docker inspect -f '{{.HostConfig.Memory}}' $RMQ" "4294967296"
  check "RabbitMQ sizes itself to that limit" \
    "sudo docker exec -u rabbitmq $RMQ rabbitmqctl -q eval 'vm_memory_monitor:get_total_memory().'" "4294967296"
  check "RabbitMQ data in its named volume" \
    "sudo docker inspect -f '{{range .Mounts}}{{if eq .Destination \"/var/lib/rabbitmq\"}}{{.Type}} {{.Name}}{{end}}{{end}}' $RMQ" \
    "volume ${SERVICES_PROJECT}_rabbitmq-data"
  check "RabbitMQ logs ship through the loki driver" \
    "sudo docker inspect -f '{{.HostConfig.LogConfig.Type}} {{index .HostConfig.LogConfig.Config \"loki-url\"}}' $RMQ" \
    "loki $LOKI_URL"
  check "RabbitMQ's local log copy capped" \
    "sudo docker inspect -f '{{index .HostConfig.LogConfig.Config \"max-size\"}} {{index .HostConfig.LogConfig.Config \"max-file\"}}' $RMQ" \
    "10m 3"
  check "AMQP on loopback and the mesh only" \
    "sudo ss -Htln 'sport = :5672' | awk '{print \$4}' | sort -u | paste -sd ' ' -" "$SELF_ADDRESS:5672 127.0.0.1:5672"
  check "RabbitMQ management on loopback only" \
    "sudo ss -Htln 'sport = :15672' | awk '{print \$4}' | sort -u | paste -sd ' ' -" "127.0.0.1:15672"
  check "No RabbitMQ guest user" \
    "sudo docker exec -u rabbitmq $RMQ rabbitmqctl -q list_users | awk '{print \$1}' | grep -cx guest || true" "0"
  check "No loki driver push errors in the last hour" \
    "sudo journalctl -u docker --since '-1h' --no-pager | grep -ci 'error sending batch' || true" "0"

  echo ""
  echo "[Files gateway, from here]"
  check "Gateway's migrations recorded" \
    "sudo docker exec $PG psql -X -At -U postgres -d gateway -c 'SELECT count(*) FROM migrations'" "3"
  check "DAG indexer's schema present" \
    "sudo docker exec $PG psql -X -At -U postgres -d gateway -c \"SELECT count(*) FROM pg_namespace WHERE nspname = 'dag-indexer'\"" "1"
  check "Object-mapping indexer answers over the mesh" \
    "curl -s -m 5 -o /dev/null -w '%{http_code}' http://$GATEWAY_MESH_ADDRESS:3000/health" "200"
  check "File retriever answers over the mesh" \
    "curl -s -m 5 -o /dev/null -w '%{http_code}' http://$GATEWAY_MESH_ADDRESS:8090/health" "200"

  echo ""
  echo "[Backends, from here]"
  check "Auth's migrations recorded" \
    "sudo docker exec $PG psql -X -At -U postgres -d auth -c 'SELECT count(*) FROM auth_migrations'" "8"
  # the publish worker is the only on-chain publisher: a second consumer, on any
  # host, would hand out the same nonces
  check "Exactly one consumer on the publish queue" \
    "sudo docker exec -u rabbitmq $RMQ rabbitmqctl -q list_queues name consumers | awk '\$1 == \"publish-manager\" {print \$2}'" "1"
}

# by compose service name, in the backend project
backend_container() {
  echo "\$(sudo docker ps -a -q --filter label=com.docker.compose.project=$BACKEND_PROJECT --filter label=com.docker.compose.service=$1)"
}

backend_checks() {
  local service port c
  echo ""
  echo "[Backend deploy]"
  check "Compose files and env files in place" \
    "cd $BACKEND_DIR && stat -c '%n %a %U' $BACKEND_FILES | paste -sd ' ' -" \
    "$(for file in $BACKEND_FILES; do [[ $file == *.yml ]] && echo "$file 644 ubuntu" || echo "$file 600 ubuntu"; done | paste -sd ' ' -)"
  # only the public host runs the migrations
  if [[ $ROLE == public ]]; then
    check "Migrations ran with the deployed backend image" "cat $BACKEND_DIR/migrated-image" "$BACKEND_IMAGE"
  fi
  check "Hasura's assets copied from that image" \
    "c=$(backend_container hasura-assets); sudo docker inspect -f '{{.Config.Image}} {{.State.Status}} {{.State.ExitCode}}' \$c" \
    "$BACKEND_IMAGE exited 0"
  for entry in $BACKEND_SERVICES; do
    service="${entry%%=*}"
    port="${entry#*=}"
    c="$(backend_container "$service")"
    check "$service healthy" "sudo docker inspect -f '{{.State.Health.Status}}' $c" "healthy"
    check "$service image" "sudo docker inspect -f '{{.Config.Image}}' $c" \
      "$([[ $service == hasura ]] && echo "$HASURA_IMAGE" || echo "$BACKEND_IMAGE")"
    # the running container's config hash is the files': no change is waiting on a restart
    check "$service matches the compose files" \
      "cd $BACKEND_DIR && [ \"\$(sudo docker compose config --hash $service | awk '{print \$2}')\" = \"\$(sudo docker inspect -f '{{index .Config.Labels \"com.docker.compose.config-hash\"}}' $c)\" ] && echo match || echo differs" \
      "match"
    check "$service restarts unless stopped" "sudo docker inspect -f '{{.HostConfig.RestartPolicy.Name}}' $c" "unless-stopped"
    check "$service's local log copy capped" \
      "sudo docker inspect -f '{{index .HostConfig.LogConfig.Config \"max-size\"}} {{index .HostConfig.LogConfig.Config \"max-file\"}}' $c" \
      "10m 3"
    check "$service logs ship through the loki driver" \
      "sudo docker inspect -f '{{.HostConfig.LogConfig.Type}} {{index .HostConfig.LogConfig.Config \"loki-url\"}}' $c" \
      "loki $LOKI_URL"
    check "$service on loopback only" \
      "sudo ss -Htln 'sport = :$port' | awk '{print \$4}' | sort -u | paste -sd ' ' -" "127.0.0.1:$port"
  done
  for entry in $BACKEND_SERVICES; do
    service="${entry%%=*}"
    [[ $service == hasura ]] && continue
    check "$service file cache in its named volume" \
      "sudo docker inspect -f '{{range .Mounts}}{{if eq .Destination \"/usr/src/app/apps/backend/.cache\"}}{{.Type}} {{.Name}}{{end}}{{end}}' $(backend_container "$service")" \
      "volume ${BACKEND_PROJECT}_files_cache"
  done
  check "Hasura metadata consistent" \
    "curl -s -o /dev/null -w '%{http_code}' 'http://127.0.0.1:6565/healthz?strict=true'" "200"
  check "API answers" "curl -s -o /dev/null -w '%{http_code}' http://127.0.0.1:3000/health" "204"
  check "Postgres and RabbitMQ reachable over the mesh" \
    "timeout 5 bash -c 'echo > /dev/tcp/$SERVICES_MESH_ADDRESS/5432' && timeout 5 bash -c 'echo > /dev/tcp/$SERVICES_MESH_ADDRESS/5672' && echo reachable" \
    "reachable"
  check "Containers reach Postgres over the mesh" \
    "sudo docker exec $(backend_container "$API_SERVICE") node -e \"setTimeout(() => process.exit(1), 5000); require('net').connect(5432, '$SERVICES_MESH_ADDRESS').on('connect', () => { console.log('reachable'); process.exit(0) }).on('error', () => process.exit(1))\"" \
    "reachable"
  check "No loki driver push errors in the last hour" \
    "sudo journalctl -u docker --since '-1h' --no-pager | grep -ci 'error sending batch' || true" "0"

  echo ""
  echo "[Ingress]"
  check "nginx running" "systemctl is-active nginx" "active"
  check "nginx enabled" "systemctl is-enabled nginx" "enabled"
  check "nginx configuration valid" "sudo nginx -t -q 2>&1 | grep -c emerg || true" "0"
  check "Only the role's site enabled" "ls /etc/nginx/sites-enabled | paste -sd ' ' -" "auto-drive"
  check "Certificate covers the site's names" \
    "sudo openssl x509 -in /etc/letsencrypt/live/$APP_HOST/cert.pem -noout -ext subjectAltName | grep -o 'DNS:[^,]*' | cut -d: -f2 | sort | paste -sd ' ' -" \
    "$(tr ' ' '\n' <<< "$CERT_NAMES" | sort | paste -sd ' ' -)"
  check "Certificate from Let's Encrypt, not its staging CA" \
    "sudo openssl x509 -in /etc/letsencrypt/live/$APP_HOST/cert.pem -noout -issuer | grep -q STAGING && echo staging || echo production" \
    "production"
  check "Certificate valid for 14 days more" \
    "sudo openssl x509 -in /etc/letsencrypt/live/$APP_HOST/cert.pem -noout -checkend 1209600 >/dev/null && echo valid" "valid"
  check "Renewals reload nginx" \
    "sudo grep -c '^renew_hook = systemctl reload nginx' /etc/letsencrypt/renewal/$APP_HOST.conf" "1"
  check "Renewal timer active" "systemctl is-active certbot.timer" "active"
  check "API through nginx" \
    "curl -sk -o /dev/null -w '%{http_code}' --resolve $APP_HOST:443:127.0.0.1 https://$APP_HOST/api/health" "204"
  check "Hasura through nginx" \
    "curl -sk -o /dev/null -w '%{http_code}' --resolve $APP_HOST:443:127.0.0.1 https://$APP_HOST/hasura/healthz" "200"
  check "HTTP redirects to HTTPS" \
    "curl -s -o /dev/null -w '%{http_code} %{redirect_url}' --resolve $APP_HOST:80:127.0.0.1 http://$APP_HOST/api/health" \
    "301 https://$APP_HOST/api/health"
}

# by compose service name, in the auth project
auth_container() {
  echo "\$(sudo docker ps -a -q --filter label=com.docker.compose.project=$AUTH_PROJECT --filter label=com.docker.compose.service=$1)"
}

# names only: a value never leaves the host
holds_seeds() {
  echo "sudo docker inspect -f '{{range .Config.Env}}{{println .}}{{end}}' $(backend_container "$1") | cut -d= -f1 | grep -cx PRIVATE_KEYS_PATH || true"
}

private_checks() {
  local auth
  echo ""
  echo "[Publish worker]"
  # the only on-chain publisher: its signing accounts' nonces are tracked in one process
  check "Exactly one publish worker container" \
    "sudo docker ps -q --filter label=com.docker.compose.service=backend-publish-worker | wc -l" "1"
  check "The publish worker holds the signing seeds" "$(holds_seeds backend-publish-worker)" "1"
  check "The worker holds the signing seeds" "$(holds_seeds backend-worker)" "1"
  check "The API does not" "$(holds_seeds backend-api)" "0"
  check "Object-mapping indexer answers over the mesh" \
    "curl -s -m 5 -o /dev/null -w '%{http_code}' http://$GATEWAY_MESH_ADDRESS:3000/health" "200"
  check "File retriever answers over the mesh" \
    "curl -s -m 5 -o /dev/null -w '%{http_code}' http://$GATEWAY_MESH_ADDRESS:8090/health" "200"

  echo ""
  echo "[Auth]"
  auth="$(auth_container auth)"
  check "Compose file, .env and auth.env in place" \
    "cd $AUTH_DIR && stat -c '%n %a %U' docker-compose.yml .env auth.env | paste -sd ' ' -" \
    "docker-compose.yml 644 ubuntu .env 600 ubuntu auth.env 600 ubuntu"
  check "Auth's migrations finished cleanly" \
    "sudo docker inspect -f '{{.State.Status}} {{.State.ExitCode}}' $(auth_container auth-migrate)" "exited 0"
  check "Auth healthy" "sudo docker inspect -f '{{.State.Health.Status}}' $auth" "healthy"
  check "Auth image" "sudo docker inspect -f '{{.Config.Image}}' $auth" "$AUTH_IMAGE"
  # the running container's config hash is the files': no change is waiting on a restart
  check "Auth matches the compose file" \
    "cd $AUTH_DIR && [ \"\$(sudo docker compose config --hash auth | awk '{print \$2}')\" = \"\$(sudo docker inspect -f '{{index .Config.Labels \"com.docker.compose.config-hash\"}}' $auth)\" ] && echo match || echo differs" \
    "match"
  check "Auth restarts unless stopped" "sudo docker inspect -f '{{.HostConfig.RestartPolicy.Name}}' $auth" "unless-stopped"
  check "Auth logs ship through the loki driver, capped" \
    "sudo docker inspect -f '{{.HostConfig.LogConfig.Type}} {{index .HostConfig.LogConfig.Config \"loki-url\"}} {{index .HostConfig.LogConfig.Config \"max-size\"}} {{index .HostConfig.LogConfig.Config \"max-file\"}}' $auth" \
    "loki $LOKI_URL 10m 3"
  check "Auth on loopback only" \
    "sudo ss -Htln 'sport = :$AUTH_PORT' | awk '{print \$4}' | sort -u | paste -sd ' ' -" "127.0.0.1:$AUTH_PORT"
  check "Auth answers" "curl -s -o /dev/null -w '%{http_code}' http://127.0.0.1:$AUTH_PORT/health" "204"
  check "Auth through nginx" \
    "curl -sk -o /dev/null -w '%{http_code}' --resolve $AUTH_HOST:443:127.0.0.1 https://$AUTH_HOST/health" "204"
  # staff onboard on the auth port, through an SSH tunnel; the internet can't
  check "Onboarding refused through nginx" \
    "curl -sk -o /dev/null -w '%{http_code}' -X POST --resolve $AUTH_HOST:443:127.0.0.1 https://$AUTH_HOST/users/@me/onboard" "403"
  check "Auth's HTTP redirects to HTTPS" \
    "curl -s -o /dev/null -w '%{http_code} %{redirect_url}' --resolve $AUTH_HOST:80:127.0.0.1 http://$AUTH_HOST/health" \
    "301 https://$AUTH_HOST/health"
}

# by compose service name, in the farmer project
farmer_container() {
  echo "\$(sudo docker ps -a -q --filter label=com.docker.compose.project=$FARMER_PROJECT --filter label=com.docker.compose.service=$1)"
}

# whether a container's args hold a JSON fragment, without printing them: the
# farmer's hold the host's address
has_args() {
  echo "sudo docker inspect -f '{{json .Args}}' $1 | grep -qF '$2' && echo yes || echo no"
}

farmer_rpc() {
  echo "sudo docker exec $(farmer_container node) curl -s -m 5 -H 'Content-Type: application/json' -d '{\"id\":1,\"jsonrpc\":\"2.0\",\"method\":\"$1\"}' http://localhost:9944"
}

farmer_checks() {
  local node farmer service c port ports_re sync_state restarts first second r1 r2 n1 f1 n2 f2
  node="$(farmer_container node)"
  farmer="$(farmer_container farmer)"
  echo ""
  echo "[Farmer]"
  check "Compose file and .env in place" \
    "cd $FARMER_DIR && stat -c '%n %a %U' docker-compose.yml .env | paste -sd ' ' -" \
    "docker-compose.yml 644 ubuntu .env 600 ubuntu"
  for service in node farmer; do
    c="$(farmer_container "$service")"
    # the running container's config hash is the file's: no change is waiting on a restart
    check "Farmer's $service matches the compose file" \
      "cd $FARMER_DIR && [ \"\$(sudo docker compose config --hash $service | awk '{print \$2}')\" = \"\$(sudo docker inspect -f '{{index .Config.Labels \"com.docker.compose.config-hash\"}}' $c)\" ] && echo match || echo differs" \
      "match"
    check "Farmer's $service running" "sudo docker inspect -f '{{.State.Status}}' $c" "running"
    check "Farmer's $service restarts unless stopped" "sudo docker inspect -f '{{.HostConfig.RestartPolicy.Name}}' $c" "unless-stopped"
    check "Farmer's $service logs ship through the loki driver, capped" \
      "sudo docker inspect -f '{{.HostConfig.LogConfig.Type}} {{index .HostConfig.LogConfig.Config \"loki-url\"}} {{index .HostConfig.LogConfig.Config \"max-size\"}} {{index .HostConfig.LogConfig.Config \"max-file\"}}' $c" \
      "loki $LOKI_URL 10m 3"
  done
  check "Farmer's node healthy" "sudo docker inspect -f '{{.State.Health.Status}}' $node" "healthy"
  check "Farmer's node image" "sudo docker inspect -f '{{.Config.Image}}' $node" "$FARMER_NODE_IMAGE"
  check "Farmer's node on Chronos" "$(has_args "$node" '"--chain","chronos"')" "yes"
  check "Farmer's node serves a farmer" "$(has_args "$node" '"--farmer"')" "yes"
  check "Farmer's node syncs $FARMER_SYNC" "$(has_args "$node" "\"--sync\",\"$FARMER_SYNC\"")" "yes"
  check "Farmer's node listens on $FARMER_NODE_PORT" \
    "$(has_args "$node" "\"--listen-on\",\"/ip4/0.0.0.0/tcp/$FARMER_NODE_PORT\"")" "yes"
  check "Farmer's node's DSN listens on $FARMER_NODE_DSN_PORT" \
    "$(has_args "$node" "\"--dsn-listen-on\",\"/ip4/0.0.0.0/tcp/$FARMER_NODE_DSN_PORT\"")" "yes"
  check "Farmer's node on Chronos (RPC)" "$(farmer_rpc system_chain)" '"result":"Autonomys Chronos Testnet"' contains
  check "Farmer's node has peers" \
    "$(farmer_rpc system_health) | grep -o '\"peers\":[0-9]*' | grep -qv '\"peers\":0\$' && echo peered" \
    "peered"

  check "Farmer image" "sudo docker inspect -f '{{.Config.Image}}' $farmer" "$FARMER_IMAGE"
  check "Farm of $FARM_SIZE at /var/subspace" \
    "$(has_args "$farmer" "\"path=/var/subspace,size=$FARM_SIZE\"")" "yes"
  check "Farmer pays its rewards to $REWARD_ADDRESS" \
    "$(has_args "$farmer" "\"--reward-address\",\"$REWARD_ADDRESS\"")" "yes"
  check "Farmer listens on $FARMER_PORT" \
    "$(has_args "$farmer" "\"--listen-on\",\"/ip4/0.0.0.0/tcp/$FARMER_PORT\"")" "yes"
  check "Farmer advertises one of this host's addresses on $FARMER_PORT" \
    "a=\$(sudo docker inspect -f '{{json .Args}}' $farmer | grep -oE '\"--external-address\",\"/ip4/[0-9.]+/tcp/$FARMER_PORT\"' | sed -E 's|.*/ip4/([0-9.]+)/.*|\\1|'); [ -n \"\$a\" ] && ip -4 -o addr show | awk '{print \$4}' | cut -d/ -f1 | grep -qxF \"\$a\" && echo yes || echo no" \
    "yes"
  # the farm's own record of itself, which holds only public IDs and writes the
  # genesis hash without its 0x
  check "Farm allocated $FARM_SIZE on Chronos" \
    "sudo docker exec $farmer cat /var/subspace/single_disk_farm.json | python3 -c 'import json, sys; f = json.load(sys.stdin)[\"v0\"]; print(f[\"allocatedSpace\"], f[\"genesisHash\"])'" \
    "$FARM_BYTES ${CHRONOS_GENESIS#0x}"

  for port in $FARMER_NODE_PORT $FARMER_NODE_DSN_PORT $FARMER_PORT; do
    check "$port published on every interface" \
      "sudo ss -Htln 'sport = :$port' | awk '{print \$4}' | sort -u | paste -sd ' ' -" "0.0.0.0:$port [::]:$port"
  done
  ports_re="($FARMER_NODE_PORT|$FARMER_NODE_DSN_PORT|$FARMER_PORT)"
  check "UFW opens the farmer's ports as farmer-port, and nothing else" \
    "s=\$(sudo ufw status); echo \"\$(grep -cE '^$ports_re/tcp +ALLOW +Anywhere +# farmer-port\$' <<< \"\$s\") \$(grep -cE '^$ports_re/tcp \\(v6\\) +ALLOW +Anywhere \\(v6\\) +# farmer-port\$' <<< \"\$s\") \$(grep -c '# farmer-port\$' <<< \"\$s\")\"" \
    "3 3 6"
  # the farmer's node and farm share the disk with everything else on the host
  check "At least 50 GB free under /var/lib/docker" \
    "a=\$(df --output=avail -B1G /var/lib/docker | tail -1 | tr -d ' '); [ \"\$a\" -ge 50 ] && echo ok || echo \"\$a GB free\"" "ok"
  # the loki driver's local copy, which `docker logs` reads, holds only the
  # farmer's current run
  echo "  rewards signed since the farmer last started: $(ssh -o ConnectTimeout=5 "$HOST" "sudo docker logs $farmer 2>&1 | grep -c 'Successfully signed reward hash' || true" 2>/dev/null || echo unknown)"

  echo ""
  echo "[Farmer node sync]"
  # Two samples a minute apart. A container that restarted in between exited
  # with an error that only Loki has: `docker logs` reads the loki driver's
  # local copy, which holds just the current run.
  sync_state="$(farmer_rpc system_syncState)"
  # each container's restart count, or none while it doesn't exist
  restarts="for c in \"$node\" \"$farmer\"; do sudo docker inspect -f '{{.RestartCount}}' \"\$c\" 2>/dev/null || echo none; done | paste -sd ' ' -"
  r1="$(ssh -o ConnectTimeout=5 "$HOST" "$restarts" 2>/dev/null || true)"
  first="$(ssh -o ConnectTimeout=5 "$HOST" "$sync_state" 2>/dev/null || true)"
  echo "  now:       ${first:-no answer}"
  sleep 60
  second="$(ssh -o ConnectTimeout=5 "$HOST" "$sync_state" 2>/dev/null || true)"
  r2="$(ssh -o ConnectTimeout=5 "$HOST" "$restarts" 2>/dev/null || true)"
  echo "  +60s:      ${second:-no answer}"
  read -r n1 f1 <<< "$r1"
  read -r n2 f2 <<< "$r2"
  steady() {
    if [[ -z "$3" || "$3" == none ]]; then
      report "$1" "no container" "steady"
    elif [[ "$3" == "$4" ]]; then
      report "$1" "steady" "steady"
    else
      report "$1" "restarted, $3 -> $4 restarts; its errors are in Loki under compose_project=\"$FARMER_PROJECT\", compose_service=\"$2\"" "steady"
    fi
  }
  steady "Farmer's node not restarting" node "$n1" "$n2"
  steady "Farmer not restarting" farmer "$f1" "$f2"
  current() { grep -o '"currentBlock":[0-9]*' <<< "$1" | cut -d: -f2; }
  if [[ -n "$(current "$first")" && -n "$(current "$second")" && "$(current "$second")" -gt "$(current "$first")" ]]; then
    report "Farmer's node importing blocks" "advancing" "advancing"
  else
    report "Farmer's node importing blocks" "not advancing" "advancing"
  fi
}

case "$ROLE" in
  files-gateway)
    files_gateway_checks
    farmer_checks
    ;;
  services) services_checks ;;
  public)
    backend_checks
    farmer_checks
    ;;
  private)
    backend_checks
    private_checks
    ;;
esac

echo ""
if [[ $ERRORS -eq 0 ]]; then
  echo -e "=== Results: ${GREEN}$PASS passed${NC}, 0 failed ==="
else
  echo -e "=== Results: ${GREEN}$PASS passed${NC}, ${RED}$ERRORS failed${NC} ==="
fi
exit $ERRORS
