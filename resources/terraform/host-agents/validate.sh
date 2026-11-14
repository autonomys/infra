#!/usr/bin/env bash
# Verify a server's host agent, on the server and in VictoriaMetrics.
# Usage: ./validate.sh <server-name> <ssh-host> [monitoring-ssh-host]
#   server-name is its key in local.agents; ssh-host is how you reach it
#   (user@address, or a name from your SSH config); monitoring-ssh-host defaults
#   to "monitoring-loki"
set -euo pipefail

if [[ $# -lt 2 ]]; then
  sed -n '3,6p' "$0" | sed 's/^# \{0,1\}//'
  exit 2
fi

SERVER="$1"
HOST="$2"
MONITORING="${3:-monitoring-loki}"
ERRORS=0
PASS=0

GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m'

report() {
  local desc="$1" result="$2" expected="$3"
  if [[ "$result" == *"$expected"* ]]; then
    echo -e "  ${GREEN}PASS${NC}: $desc"
    PASS=$((PASS + 1))
  else
    echo -e "  ${RED}FAIL${NC}: $desc"
    echo "        expected: '$expected'"
    echo "        got:      '$result'"
    ERRORS=$((ERRORS + 1))
  fi
}

# runs on the server, as root
check() {
  report "$1" "$(ssh -o ConnectTimeout=5 "$HOST" "sudo -n bash -c $(printf %q "$2")" 2>/dev/null || echo "COMMAND_FAILED")" "$3"
}

# runs a MetricsQL query on the monitoring host and prints <ok> only when every
# returned value satisfies <test> (a Python expression on v) and there is at
# least one, so a failure can't pass as a substring
vm_check() {
  local desc="$1" query="$2" test="$3" ok="$4"
  local cmd
  cmd=$(printf "curl -s http://127.0.0.1:8428/api/v1/query --data-urlencode %q | python3 -c %q" \
    "query=$query" \
    "import json,sys; r=json.load(sys.stdin)['data']['result']; vs=[float(x['value'][1]) for x in r]; print('$ok' if vs and all(($test) for v in vs) else 'got %s' % vs)")
  report "$desc" "$(ssh -o ConnectTimeout=5 "$MONITORING" "$cmd" 2>/dev/null || echo "COMMAND_FAILED")" "$ok"
}

echo "=== Validating the host agent on $SERVER ==="

echo ""
echo "[On the server]"
for svc in vmagent node-exporter smartctl-exporter textfiles; do
  check "$svc healthy" \
    "docker ps --filter label=com.docker.compose.project=host-agent --filter label=com.docker.compose.service=$svc --format '{{.Status}}'" "(healthy)"
done
check "Agent ports listen on loopback only" \
  "p=\$(ss -ltnH | awk '{print \$4}' | grep -E ':(8430|9100|9633)\$' | grep -vE '^127\\.' | tr '\n' ' '); [ -z \"\$p\" ] && echo loopback-only || echo \"exposed: \$p\"" \
  "loopback-only"
check "Credential readable by the deploy user only" \
  "d=\$(docker ps --filter label=com.docker.compose.project=host-agent --filter label=com.docker.compose.service=vmagent --format '{{.Label \"com.docker.compose.project.working_dir\"}}'); stat -c '%a' \"\$d/credentials\" \"\$d/credentials/vmetrics-username\" \"\$d/credentials/vmetrics-password\" \"\$d/.env\" | tr '\n' ' '" \
  "700 600 600 600"
check "vmagent has written to vmetrics" \
  "curl -fsS http://127.0.0.1:8430/metrics | awk '/^vmagent_remotewrite_requests_total\\{.*status_code=\"2XX\"/ {n += \$NF} END {print (n > 0 ? \"writing\" : \"no successful writes\")}'" \
  "writing"
check "vmagent has dropped nothing" \
  "curl -fsS http://127.0.0.1:8430/metrics | awk '/^vmagent_remotewrite_packets_dropped_total/ {n += \$NF} END {print (n == 0 ? \"none-dropped\" : n \" dropped\")}'" \
  "none-dropped"
check "node_exporter serves both textfiles" \
  "curl -fsS http://127.0.0.1:9100/metrics | grep -cE '^node_(disks_expected|boot_efi) '" "2"

echo ""
echo "[In VictoriaMetrics]"
vm_check "Every scrape target up" "up{host=\"$SERVER\"}" "v == 1" all-up
vm_check "Metrics fresh" "time() - max(timestamp(up{host=\"$SERVER\"}))" "v < 60" fresh
vm_check "smartctl sees the expected disks" \
  "smartctl_devices{host=\"$SERVER\"} - on(host) node_disks_expected{host=\"$SERVER\"}" "v == 0" disks-match
vm_check "Boot disks carry GRUB, or the server boots UEFI" \
  "node_bootloader_grub_present{host=\"$SERVER\"} or on(host) (node_boot_efi{host=\"$SERVER\"} == 1)" "v == 1" boot-ok

echo ""
if [[ $ERRORS -eq 0 ]]; then
  echo -e "=== Results: ${GREEN}$PASS passed${NC}, 0 failed ==="
else
  echo -e "=== Results: ${GREEN}$PASS passed${NC}, ${RED}$ERRORS failed${NC} ==="
fi
exit $ERRORS
