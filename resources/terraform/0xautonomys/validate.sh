#!/usr/bin/env bash
# Verify that the live 0xautonomys instance matches the infrastructure spec.
# Usage: ./validate.sh [ssh-host]
#   ssh-host defaults to "0xautonomys" (must be configured in ~/.ssh/config)
set -euo pipefail

HOST="${1:-0xautonomys}"
ERRORS=0
PASS=0

GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m'

check() {
  local desc="$1" cmd="$2" expected="$3"
  result=$(ssh -o ConnectTimeout=5 "$HOST" "$cmd" 2>/dev/null || echo "COMMAND_FAILED")
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

echo "=== Validating $HOST ==="
echo ""

# --- Instance basics ---
echo "[Instance]"
check "Hostname" "hostname" "0xautonomys"
check "Timezone" "timedatectl show -p Timezone --value" "UTC"
check "Ubuntu 24.04" "lsb_release -rs" "24.04"

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

# --- Services ---
echo ""
echo "[Services]"
check "fail2ban running" "systemctl is-active fail2ban" "active"
check "unattended-upgrades active" "systemctl is-active unattended-upgrades" "active"
check "ModemManager disabled" \
  "systemctl is-enabled ModemManager 2>/dev/null || echo disabled" "disabled"
check "multipathd disabled" \
  "systemctl is-enabled multipathd 2>/dev/null || echo disabled" "disabled"

# --- Users ---
echo ""
echo "[Users]"
check "autonomys user exists" "id autonomys" "uid="
check "sudoers entry (ubuntu->autonomys)" \
  "sudo cat /etc/sudoers.d/ubuntu-to-autonomys" "ubuntu ALL=(autonomys) NOPASSWD: ALL"
check "linger enabled for autonomys" \
  "loginctl show-user autonomys -p Linger --value 2>/dev/null || echo no" "yes"
check "autonomys SSH authorized_keys" \
  "sudo test -f /home/autonomys/.ssh/authorized_keys && echo exists" "exists"

# --- Node.js ---
echo ""
echo "[Node.js]"
check "System Node.js installed" "/usr/bin/node --version" "v22"
check "openclaw symlink exists" \
  "ls -la /usr/local/bin/openclaw 2>/dev/null || echo missing" "/home/autonomys/.nvm"

# --- journald ---
echo ""
echo "[Journald]"
check "journald SystemMaxUse" \
  "cat /etc/systemd/journald.conf.d/openclaw.conf" "SystemMaxUse=500M"
check "journald MaxRetentionSec" \
  "cat /etc/systemd/journald.conf.d/openclaw.conf" "MaxRetentionSec=30day"

# --- fail2ban config ---
echo ""
echo "[fail2ban Config]"
check "fail2ban bantime" "cat /etc/fail2ban/jail.local" "bantime"
check "fail2ban maxretry" "cat /etc/fail2ban/jail.local" "maxretry = 5"

# --- Unattended upgrades ---
echo ""
echo "[Unattended Upgrades]"
check "Auto-reboot disabled" \
  "cat /etc/apt/apt.conf.d/50unattended-upgrades-local" 'Automatic-Reboot "false"'

# --- OpenClaw (as autonomys user) ---
echo ""
echo "[OpenClaw]"
check "Gateway service running" \
  "sudo -u autonomys XDG_RUNTIME_DIR=/run/user/\$(id -u autonomys) systemctl --user is-active openclaw-gateway" "active"
check "EnvironmentFile override" \
  "sudo -u autonomys XDG_RUNTIME_DIR=/run/user/\$(id -u autonomys) systemctl --user cat openclaw-gateway 2>/dev/null" "EnvironmentFile"
check ".env exists" \
  "sudo test -f /home/autonomys/.openclaw/.env && echo exists" "exists"
check ".env permissions (600)" \
  "sudo stat -c '%a' /home/autonomys/.openclaw/.env" "600"

# --- Workspace ---
echo ""
echo "[Workspace]"
check "SOUL.md" \
  "sudo test -f /home/autonomys/.openclaw/workspace/SOUL.md && echo exists" "exists"
check "HEARTBEAT.md" \
  "sudo test -f /home/autonomys/.openclaw/workspace/HEARTBEAT.md && echo exists" "exists"
check "Auto Drive skill" \
  "sudo test -d /home/autonomys/.openclaw/workspace/skills/auto-drive && echo exists" "exists"

# --- Cron ---
echo ""
echo "[Cron]"
check "Disk check cron job" \
  "crontab -l 2>/dev/null" "DISK WARNING"

echo ""
if [[ $ERRORS -eq 0 ]]; then
  echo -e "=== Results: ${GREEN}$PASS passed${NC}, 0 failed ==="
else
  echo -e "=== Results: ${GREEN}$PASS passed${NC}, ${RED}$ERRORS failed${NC} ==="
fi
exit $ERRORS
