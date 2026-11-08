#!/usr/bin/env bash
# Verify that the live monitoring host matches the infrastructure spec.
# Usage: ./validate.sh [ssh-host]
#   ssh-host defaults to "monitoring-loki" (configure it in ~/.ssh/config, or
#   pass ubuntu@<HOST_IPv4>)
set -euo pipefail

HOST="${1:-monitoring-loki}"
SITE="monitoring-loki"
LOKI_DOMAIN="logging.subspace.network"
GRAFANA_DOMAIN="grafana.subspace.network"
STACK_DIR="/home/ubuntu/monitoring"
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

# runs on the host
check() {
  report "$1" "$(ssh -o ConnectTimeout=5 "$HOST" "$2" 2>/dev/null || echo "COMMAND_FAILED")" "$3"
}

# runs here, from outside the host
check_local() {
  report "$1" "$(bash -c "$2" 2>/dev/null || echo "COMMAND_FAILED")" "$3"
}

echo "=== Validating $HOST ==="
echo ""

# --- Host basics ---
echo "[Host]"
check "Hostname" "hostname" "$SITE"
check "Timezone" "timedatectl show -p Timezone --value" "UTC"
check "Ubuntu 24.04" "lsb_release -rs" "24.04"

# --- Storage ---
echo ""
echo "[Storage]"
check "/ on RAID 1" "sudo mdadm --detail \$(findmnt -no SOURCE /) | grep 'Raid Level'" "raid1"
check "/boot on RAID 1" "sudo mdadm --detail \$(findmnt -no SOURCE /boot) | grep 'Raid Level'" "raid1"
check "/srv on RAID 1" "sudo mdadm --detail \$(findmnt -no SOURCE /srv) | grep 'Raid Level'" "raid1"
check "No array other than RAID 1" "grep -E '^md' /proc/mdstat | grep -vc raid1 || true" "0"
check "Every array in sync" \
  "awk '/^md/ {n++} /\\[U+\\]/ {u++} END {print (n > 0 && n == u) ? \"synced\" : n \" arrays, \" u \" in sync\"}' /proc/mdstat" \
  "synced"
# a disk swap leaves the new disk without boot code unless grub-install is run on it
check "Boot code on every disk" \
  "if [ -d /sys/firmware/efi ]; then e=\$(sudo efibootmgr | grep -ci ubuntu); d=\$(lsblk -dn -o TYPE | grep -c disk); [ \$e -ge \$d ] && echo all-disks || echo \"\$e boot entries for \$d disks\"; else for d in \$(lsblk -dnp -o NAME,TYPE | awk '\$2 == \"disk\" {print \$1}'); do sudo dd if=\$d bs=512 count=1 2>/dev/null | grep -aq GRUB || echo \"\$d:no-grub\"; done | grep . || echo all-disks; fi" \
  "all-disks"
# install_devices can be set while grub-pc itself is absent, so check both
check "GRUB updates target both disks" \
  "[ -d /sys/firmware/efi ] && echo uefi || { dpkg-query -W -f='\${Status}' grub-pc 2>/dev/null | grep -q 'install ok installed' || { echo 'grub-pc not installed'; exit 0; }; n=\$(sudo debconf-show grub-pc 2>/dev/null | sed -n 's/^\\* grub-pc\\/install_devices: //p' | tr ',' '\n' | grep -c .); [ \$n -ge 2 ] && echo both || echo \"\$n install_devices\"; }" \
  "both"
check "SMART healthy on every disk" \
  "for d in \$(lsblk -dnp -o NAME,TYPE | awk '\$2 == \"disk\" {print \$1}'); do sudo smartctl -H \$d | grep -qE 'PASSED|OK' || echo \"\$d:failing\"; done | grep . || echo healthy" \
  "healthy"

# --- SSH hardening ---
echo ""
echo "[SSH Hardening]"
check "PermitRootLogin disabled" \
  "sudo sshd -T 2>/dev/null | grep -i '^permitrootlogin'" "no"
check "PasswordAuthentication disabled" \
  "sudo sshd -T 2>/dev/null | grep -i '^passwordauthentication'" "no"
check "KbdInteractiveAuthentication disabled" \
  "sudo sshd -T 2>/dev/null | grep -i '^kbdinteractiveauthentication'" "no"

# --- Firewall ---
echo ""
echo "[Firewall]"
check "UFW active" "sudo ufw status" "Status: active"
check "UFW SSH rule" "sudo ufw status" "22/tcp"
check "80/443 allowed from Cloudflare ranges" \
  "n=\$(sudo ufw status | grep -c '# cloudflare'); [ \$n -ge 10 ] && echo cloudflare-only || echo \"\$n cloudflare rules\"" \
  "cloudflare-only"
check "80/443 not open to anywhere" \
  "s=\$(sudo ufw status) && { echo \"\$s\" | grep -qE '^(80|443|80,443)/tcp.*ALLOW.*Anywhere' && echo world-open || echo closed; }" \
  "closed"
# ports Docker publishes bypass UFW, so only Traefik (host network) and sshd may
# listen beyond loopback
check "Only 22, 80 and 443 listen beyond loopback" \
  "p=\$(sudo ss -ltnH | awk '{print \$4}' | grep -vE '^(127\\.[0-9.]+(%[a-z0-9]+)?|\\[::1\\]|\\[::ffff:127\\.[0-9.]+\\]):' | sed -E 's/.*:([0-9]+)\$/\\1/' | sort -un | tr '\n' ' '); [ \"\$p\" = '22 80 443 ' ] && echo only-expected-ports || echo \"listening: \$p\"" \
  "only-expected-ports"

# --- Services ---
echo ""
echo "[Services]"
# is-active prints "inactive" for a stopped unit, which contains "active"
for unit in fail2ban unattended-upgrades; do
  check "$unit running" "[ \"\$(systemctl is-active $unit)\" = active ] && echo running || echo stopped" "running"
done
check "fail2ban sshd jail" "sudo cat /etc/fail2ban/jail.local" "maxretry = 5"
check "Auto-reboot disabled" \
  "cat /etc/apt/apt.conf.d/50unattended-upgrades-local" 'Automatic-Reboot "false"'
check "Background apt timers resumed after setup" \
  "[ \"\$(systemctl is-active apt-daily.timer apt-daily-upgrade.timer | sort -u)\" = active ] && echo resumed || echo paused" \
  "resumed"

# --- Docker ---
echo ""
echo "[Docker]"
check "Docker installed" "docker --version" "Docker version"
check "Compose plugin installed" "docker compose version" "Docker Compose version"
check "ubuntu in docker group" "id -nG ubuntu" "docker"
check "journald capped" "cat /etc/systemd/journald.conf.d/size.conf" "SystemMaxUse=200M"

# --- Stack ---
echo ""
echo "[Stack]"
check "Traefik running" \
  "sudo docker compose -f $STACK_DIR/docker-compose.yml ps --format '{{.Service}}:{{.State}}'" "traefik:running"
check "Loki running" \
  "sudo docker compose -f $STACK_DIR/docker-compose.yml ps --format '{{.Service}}:{{.State}}'" "loki:running"
check "Loki ready on loopback" "curl -fsS http://127.0.0.1:3100/ready" "ready"
check "Loki caps decompressed push size" \
  "curl -fsS http://127.0.0.1:3100/config | grep -E '^  max_decompressed_size:'" "16777216"
check "Grafana running" \
  "sudo docker compose -f $STACK_DIR/docker-compose.yml ps --format '{{.Service}}:{{.State}}'" "grafana:running"
check "Grafana healthy on loopback" "curl -fsS http://127.0.0.1:3000/api/health" '"database": "ok"'
check "Grafana reaches Loki" "sudo docker exec grafana wget -qO- http://loki:3100/ready" "ready"
# Containers have no IPv6, so they depend on replies to outbound IPv4 getting
# back through any firewall in front of the box
check "Containers reach the internet over IPv4" \
  "sudo docker exec grafana nc -z -w 5 1.1.1.1 443 && echo connected || echo timed-out" "connected"
check "Grafana admin secrets readable by ubuntu only" "stat -c %a $STACK_DIR/secrets" "700"

# --- TLS ---
echo ""
echo "[TLS]"
for domain in "$LOKI_DOMAIN" "$GRAFANA_DOMAIN"; do
  check "Let's Encrypt certificate served for $domain" \
    "echo | openssl s_client -connect 127.0.0.1:443 -servername $domain 2>/dev/null | openssl x509 -noout -issuer" \
    "Let's Encrypt"
done
check "Bare-IP handshake refused" \
  "curl -sk -o /dev/null https://127.0.0.1/; rc=\$?; [ \$rc -eq 35 ] && echo rejected || echo \"curl rc=\$rc\"" \
  "rejected"

# --- Routing ---
# --resolve rather than a Host header, so curl sends the hostname in the handshake.
# The push check sends an empty stream list, which Loki rejects with 422 and
# writes nothing for; a 404 would come from Traefik, meaning it wasn't routed.
echo ""
echo "[Routing through Traefik]"
check "GET /ready answers" \
  "curl -s -o /dev/null -w '%{http_code}' --resolve $LOKI_DOMAIN:443:127.0.0.1 https://$LOKI_DOMAIN/ready" "200"
check "POST push reaches Loki" \
  "code=\$(curl -s -o /dev/null -w '%{http_code}' --resolve $LOKI_DOMAIN:443:127.0.0.1 -H 'Content-Type: application/json' -d '{\"streams\":[]}' https://$LOKI_DOMAIN/loki/api/v1/push); case \$code in 204|400|422) echo reached-loki;; *) echo \"unexpected:\$code\";; esac" \
  "reached-loki"
check "Label reads not routed" \
  "curl -s -o /dev/null -w '%{http_code}' --resolve $LOKI_DOMAIN:443:127.0.0.1 https://$LOKI_DOMAIN/loki/api/v1/labels" "404"
check "Queries not routed" \
  "curl -s -o /dev/null -w '%{http_code}' --resolve $LOKI_DOMAIN:443:127.0.0.1 'https://$LOKI_DOMAIN/loki/api/v1/query_range?query=%7Bjob%3D%22x%22%7D'" "404"
check "GET on the push path not routed" \
  "curl -s -o /dev/null -w '%{http_code}' --resolve $LOKI_DOMAIN:443:127.0.0.1 https://$LOKI_DOMAIN/loki/api/v1/push" "404"
check "Grafana served" \
  "curl -s -o /dev/null -w '%{http_code}' --resolve $GRAFANA_DOMAIN:443:127.0.0.1 https://$GRAFANA_DOMAIN/api/health" "200"
check "Grafana API refuses anonymous requests" \
  "curl -s -o /dev/null -w '%{http_code}' --resolve $GRAFANA_DOMAIN:443:127.0.0.1 https://$GRAFANA_DOMAIN/api/search" "401"

# --- From outside ---
# curl exits 7 on a refused connection and 28 on a timeout; anything else means
# the port answered from a non-Cloudflare address
echo ""
echo "[From this machine]"
ORIGIN="$(ssh -G "$HOST" | awk '$1 == "hostname" {print $2}')"
check_local "443 unreachable directly" \
  "curl -sk --connect-timeout 5 -o /dev/null https://$ORIGIN/; rc=\$?; case \$rc in 7|28) echo blocked;; *) echo \"answered, curl rc=\$rc\";; esac" \
  "blocked"
for port in 3100 3000; do
  check_local "$port unreachable directly" \
    "curl -s --connect-timeout 5 -o /dev/null http://$ORIGIN:$port/; rc=\$?; case \$rc in 7|28) echo blocked;; *) echo \"answered, curl rc=\$rc\";; esac" \
    "blocked"
done
check_local "Readiness probe through Cloudflare" \
  "curl -s -o /dev/null -w '%{http_code}' https://$LOKI_DOMAIN/ready" "200"
check_local "Reads blocked at Cloudflare" \
  "curl -s -o /dev/null -w '%{http_code}' https://$LOKI_DOMAIN/loki/api/v1/labels" "403"
check_local "Grafana login page through Cloudflare" \
  "curl -s -o /dev/null -w '%{http_code}' https://$GRAFANA_DOMAIN/login" "200"
check_local "Grafana API refuses anonymous requests through Cloudflare" \
  "curl -s -o /dev/null -w '%{http_code}' https://$GRAFANA_DOMAIN/api/search" "401"
check_local "Grafana health endpoint hides its version" \
  "b=\$(curl -s https://$GRAFANA_DOMAIN/api/health); case \"\$b\" in *'\"version\"'*) echo shown;; *'\"database\"'*) echo hidden;; *) echo no-answer;; esac" "hidden"
# Traefik's challenge handler answers 404 for an unknown token; a 403 would mean
# a Cloudflare rule is blocking Let's Encrypt's renewals
for domain in "$LOKI_DOMAIN" "$GRAFANA_DOMAIN"; do
  check_local "HTTP-01 challenge path reaches the box through Cloudflare for $domain" \
    "curl -s -o /dev/null -w '%{http_code}' http://$domain/.well-known/acme-challenge/validate-probe" "404"
done

echo ""
if [[ $ERRORS -eq 0 ]]; then
  echo -e "=== Results: ${GREEN}$PASS passed${NC}, 0 failed ==="
else
  echo -e "=== Results: ${GREEN}$PASS passed${NC}, ${RED}$ERRORS failed${NC} ==="
fi
exit $ERRORS
