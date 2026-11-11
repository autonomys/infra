#!/usr/bin/env bash
# Verify that the live Auto Drive staging files gateway matches its spec. Every
# check only reads; none touches secrets or the node's data.
# Usage: ./validate.sh [ssh-host]
#   ssh-host defaults to "auto-drive-files-gateway-chronos" (configure it in
#   ~/.ssh/config, or pass ubuntu@<HOST_IPv4>)
set -euo pipefail

HOST="${1:-auto-drive-files-gateway-chronos}"
# copied from main.tf and the gateway module's defaults: change them together
HOSTNAME_WANT="auto-drive-files-gateway-chronos"
DEPLOY_DIR="/home/ubuntu/deploy"
NODE_IMAGE="ghcr.io/autonomys/node:mainnet-2026-jan-20"
COMPOSE_PROJECT="file-retriever"
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

echo "=== Validating $HOST ==="
echo ""

echo "[Host]"
check "Hostname" "hostname" "$HOSTNAME_WANT"
check "Timezone" "timedatectl show -p Timezone --value" "UTC"
check "Ubuntu" "lsb_release -is" "Ubuntu"
check "Booted via legacy BIOS" "test -d /sys/firmware/efi && echo uefi || echo bios" "bios"

echo ""
echo "[Storage]"
for mount in / /boot; do
  check "$mount on RAID 1" \
    "sudo mdadm --detail \$(findmnt -no SOURCE $mount) | awk -F': ' '/Raid Level/ {print \$2}'" "raid1"
  check "$mount mirror in sync with both members active" \
    "d=\$(sudo mdadm --detail \$(findmnt -no SOURCE $mount)); echo \"\$d\" | grep -qE '^ *State : clean *$' && echo \"\$d\" | grep -q 'Active Devices : 2' && echo synced || echo \"out of sync: \$(echo \"\$d\" | grep -E 'State :|Active Devices :' | tr -s ' ' | tr '\\n' ';')\"" \
    "synced"
done
check "Swap on RAID 1" \
  "s=\$(swapon --noheadings --show=NAME | head -1); sudo mdadm --detail \$s | awk -F': ' '/Raid Level/ {print \$2}'" "raid1"
check "Swap mirror in sync with both members active" \
  "d=\$(sudo mdadm --detail \$(swapon --noheadings --show=NAME | head -1)); echo \"\$d\" | grep -qE '^ *State : clean *$' && echo \"\$d\" | grep -q 'Active Devices : 2' && echo synced || echo \"out of sync: \$(echo \"\$d\" | grep -E 'State :|Active Devices :' | tr -s ' ' | tr '\\n' ';')\"" \
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
check "UFW node P2P rules" \
  "sudo ufw status | grep -cE '^(30333|30433)/tcp +ALLOW .*# role-port'" "2"
check "80/443 closed" \
  "sudo ufw status | awk '{print \$1}' | grep -qE '(^|,)(80|443)(,|/)' && echo open || echo closed" "closed"

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
check "Infisical CLI installed" "command -v infisical" "/infisical" contains

echo ""
echo "[Docker]"
check "Docker installed" "docker --version" "Docker version" contains
check "Compose plugin installed" "docker compose version" "Docker Compose version" contains
check "Loki log driver plugin enabled" "sudo docker plugin inspect -f '{{.Enabled}}' loki:latest" "true"
check "ubuntu in docker group" "id -nG ubuntu | tr ' ' '\\n' | grep -cx docker" "1"
check "journald capped" "grep '^SystemMaxUse' /etc/systemd/journald.conf.d/size.conf" "SystemMaxUse=200M"

echo ""
echo "[Ports]"
# every listener bound beyond loopback, as port numbers
PUBLIC_LISTENERS="sudo ss -Htlnp | awk '\$4 !~ /^(127\\.|\\[::1\\]|\\[::ffff:127\\.)/ {n=split(\$4,a,\":\"); print a[n]}' | sort -un | tr '\\n' ' ' | sed 's/^/[/; s/ \$/]/'"
check "Only SSH and node P2P listen beyond loopback" "$PUBLIC_LISTENERS" "[22 30333 30433]"
check "Node RPC on loopback only" \
  "sudo ss -Htln 'sport = :9944' | awk '{print \$4}' | sort -u | paste -sd ' ' -" "127.0.0.1:9944"
check "Host-agent ports 8430, 9100, 9633 free" \
  "sudo ss -Htln | awk '{print \$4}' | grep -cE ':(8430|9100|9633)\$' || true" "0"
check "No node_exporter running" "pgrep -x node_exporter >/dev/null && echo running || echo absent" "absent"
check "At least 2 GB free under /var/lib" \
  "[ \$(df --output=avail -B1G /var/lib | tail -1) -ge 2 ] && echo ok" "ok"

echo ""
echo "[Gateway deploy]"
check "Gateway checkout present" "test -d $DEPLOY_DIR/auto-files-gateway/.git && echo exists" "exists"
check "Settings env file owner-only" "stat -c '%a %U' $DEPLOY_DIR/auto-files-gateway.env" "600 ubuntu"
check "Node container running" "sudo docker inspect -f '{{.State.Status}}' $NODE" "running"
check "Node container healthy" "sudo docker inspect -f '{{.State.Health.Status}}' $NODE" "healthy"
check "Node image" "sudo docker inspect -f '{{.Config.Image}}' $NODE" "$NODE_IMAGE"
check "Node on Chronos" "sudo docker inspect -f '{{json .Args}}' $NODE" '"--chain","chronos"' contains
check "Node archives blocks and state" \
  "a=\$(sudo docker inspect -f '{{json .Args}}' $NODE); echo \"\$a\" | grep -qF '\"--blocks-pruning\",\"archive\"' && echo \"\$a\" | grep -qF '\"--state-pruning\",\"archive\"' && echo archive" \
  "archive"
check "Node creates object mappings" "sudo docker inspect -f '{{json .Args}}' $NODE" '"--create-object-mappings","1"' contains
check "Node logs ship through the loki driver" \
  "sudo docker inspect -f '{{.HostConfig.LogConfig.Type}} {{index .HostConfig.LogConfig.Config \"loki-url\"}}' $NODE" \
  "loki https://logging.subspace.network/loki/api/v1/push"
check "No loki driver push errors in the last hour" \
  "sudo journalctl -u docker --since '-1h' --no-pager | grep -ci 'error sending batch' || true" "0"
check "Node RPC answers on loopback" \
  "$RPC -d '{\"id\":1,\"jsonrpc\":\"2.0\",\"method\":\"system_chain\"}'" '"result":"Autonomys Chronos Testnet"' contains
check "Node has peers" \
  "$RPC -d '{\"id\":1,\"jsonrpc\":\"2.0\",\"method\":\"system_health\"}' | grep -o '\"peers\":[0-9]*' | grep -qv '\"peers\":0\$' && echo peered" \
  "peered"

echo ""
echo "[Sync progress]"
# not a pass/fail: two samples a minute apart show whether the node is moving
SYNC_STATE="$RPC -d '{\"id\":1,\"jsonrpc\":\"2.0\",\"method\":\"system_syncState\"}'"
first="$(ssh -o ConnectTimeout=5 "$HOST" "$SYNC_STATE" 2>/dev/null || true)"
echo "  now:       $first"
sleep 60
second="$(ssh -o ConnectTimeout=5 "$HOST" "$SYNC_STATE" 2>/dev/null || true)"
echo "  +60s:      $second"
current() { grep -o '"currentBlock":[0-9]*' <<< "$1" | cut -d: -f2; }
if [[ -n "$(current "$first")" && -n "$(current "$second")" && "$(current "$second")" -gt "$(current "$first")" ]]; then
  report "Node importing blocks" "advancing" "advancing"
else
  report "Node importing blocks" "not advancing" "advancing"
fi

echo ""
if [[ $ERRORS -eq 0 ]]; then
  echo -e "=== Results: ${GREEN}$PASS passed${NC}, 0 failed ==="
else
  echo -e "=== Results: ${GREEN}$PASS passed${NC}, ${RED}$ERRORS failed${NC} ==="
fi
exit $ERRORS
