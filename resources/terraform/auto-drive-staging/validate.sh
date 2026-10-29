#!/usr/bin/env bash
# Verify that the live auto-drive staging host matches the infrastructure spec.
# Usage: ./validate.sh [ssh-host]
#   ssh-host defaults to "auto-drive-staging" (configure it in ~/.ssh/config, or
#   pass ubuntu@<HOST_IPv4>)
set -euo pipefail

HOST="${1:-auto-drive-staging}"
PRIMARY_DOMAIN="staging.auto-drive.autonomys.xyz"
DOWNLOAD_DOMAIN="download.staging.auto-drive.autonomys.xyz"
DEPLOY_DIR="/home/ubuntu/deploy/auto-drive"
SITE="auto-drive-staging-01"
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
check "Ubuntu LTS" "lsb_release -is" "Ubuntu"

# --- Storage ---
echo ""
echo "[Storage]"
check "/ on RAID 0" "sudo mdadm --detail \$(findmnt -no SOURCE /) | grep 'Raid Level'" "raid0"
check "/boot on RAID 1" "sudo mdadm --detail \$(findmnt -no SOURCE /boot) | grep 'Raid Level'" "raid1"

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

# --- Services ---
echo ""
echo "[Services]"
check "fail2ban running" "systemctl is-active fail2ban" "active"
check "unattended-upgrades active" "systemctl is-active unattended-upgrades" "active"
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
check "Loki log driver plugin" "sudo docker plugin ls" "loki"
check "ubuntu in docker group" "id -nG ubuntu" "docker"
check "journald capped" "cat /etc/systemd/journald.conf.d/size.conf" "SystemMaxUse=200M"

# --- nginx ---
echo ""
echo "[nginx]"
check "nginx running" "systemctl is-active nginx" "active"
check "nginx config valid" "sudo nginx -t 2>&1" "syntax is ok"
check "Site enabled" "ls /etc/nginx/sites-enabled/" "$SITE"
check "Default site removed" \
  "test -e /etc/nginx/sites-enabled/default && echo present || echo absent" "absent"
check "Frontend upstream configured" \
  "sudo grep -c '127.0.0.1:8080' /etc/nginx/sites-available/$SITE" "1"
check "Upload body limit raised" \
  "sudo grep -c 'client_max_body_size 1G' /etc/nginx/sites-available/$SITE" "2"
check "Default server rejects unknown hostnames" \
  "sudo grep -c 'ssl_reject_handshake on' /etc/nginx/sites-available/$SITE" "1"

# --- TLS ---
echo ""
echo "[TLS]"
check "Primary certificate present" \
  "sudo test -f /etc/letsencrypt/live/$PRIMARY_DOMAIN/fullchain.pem && echo exists" "exists"
check "Download certificate present" \
  "sudo test -f /etc/letsencrypt/live/$DOWNLOAD_DOMAIN/fullchain.pem && echo exists" "exists"
check "Renewal timer enabled" "systemctl is-enabled certbot.timer" "enabled"
check "Renewal reloads nginx" \
  "sudo cat /etc/letsencrypt/renewal-hooks/deploy/reload-nginx.sh" "systemctl reload nginx"

# --- Deploy layout ---
echo ""
echo "[Deploy Layout]"
check "Deploy directory" "test -d $DEPLOY_DIR && echo exists" "exists"
check "Compose file in place" \
  "test -f $DEPLOY_DIR/docker-compose.staging.yml && echo exists" "exists"
check "No production-named compose file in the deploy dir" \
  "test -e $DEPLOY_DIR/docker-compose.prod.yml && echo present || echo absent" "absent"
check "auto-drive checkout" "test -d $DEPLOY_DIR/src/.git && echo exists" "exists"
check "Hasura migrations present" \
  "test -d $DEPLOY_DIR/src/apps/hasura && echo exists" "exists"
check "Infisical CLI installed" "command -v infisical" "/infisical"

# --- Reachability ---
# 502 before the first deploy (no upstream yet), 200 after: both prove the vhost.
# --resolve rather than a Host header, so curl sends the hostname in the handshake.
echo ""
echo "[Reachability]"
check "nginx answers on the primary vhost" \
  "code=\$(curl -s -o /dev/null -w '%{http_code}' -k --resolve $PRIMARY_DOMAIN:443:127.0.0.1 https://$PRIMARY_DOMAIN/); case \$code in 200|301|302|502|503) echo reachable;; *) echo \"unexpected:\$code\";; esac" \
  "reachable"
check "nginx answers on the download vhost" \
  "code=\$(curl -s -o /dev/null -w '%{http_code}' -k --resolve $DOWNLOAD_DOMAIN:443:127.0.0.1 https://$DOWNLOAD_DOMAIN/api/health); case \$code in 200|301|302|404|502|503) echo reachable;; *) echo \"unexpected:\$code\";; esac" \
  "reachable"
check "Bare-IP handshake refused" \
  "curl -sk -o /dev/null https://127.0.0.1/; rc=\$?; [ \$rc -eq 35 ] && echo rejected || echo \"curl rc=\$rc\"" \
  "rejected"

# curl exits 7 on a refused connection and 28 on a timeout; anything else means
# the port answered from a non-Cloudflare address
ORIGIN="$(ssh -G "$HOST" | awk '$1 == "hostname" {print $2}')"
check_local "443 unreachable directly from this machine" \
  "curl -sk --connect-timeout 5 -o /dev/null https://$ORIGIN/; rc=\$?; case \$rc in 7|28) echo blocked;; *) echo \"answered, curl rc=\$rc\";; esac" \
  "blocked"

echo ""
if [[ $ERRORS -eq 0 ]]; then
  echo -e "=== Results: ${GREEN}$PASS passed${NC}, 0 failed ==="
else
  echo -e "=== Results: ${GREEN}$PASS passed${NC}, ${RED}$ERRORS failed${NC} ==="
fi
exit $ERRORS
