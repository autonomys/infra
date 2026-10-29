#!/bin/bash

# Creates the `ubuntu` user Terraform connects as. The OS image on the box ships
# root-only with no cloud-init, so this runs once by hand as root after first boot:
#
#   curl -fsSL https://raw.githubusercontent.com/autonomys/infra/main/resources/terraform/auto-drive-staging/first-boot.sh -o first-boot.sh
#   bash first-boot.sh
#
# The key comes from root's authorized_keys, where installimage copies the rescue
# key. Failing that: SSH_PUBLIC_KEY='ssh-ed25519 AAAA... deployer' bash first-boot.sh
#
# Keep it minimal. Everything else belongs in scripts/auto-drive-host-bootstrap.sh,
# which Terraform re-runs, so it cannot drift.

set -euo pipefail

if [ "$(id -u)" -ne 0 ]; then
  echo "Run this as root." >&2
  exit 1
fi

TARGET_USER="${TARGET_USER:-ubuntu}"
SSH_PUBLIC_KEY="${SSH_PUBLIC_KEY:-}"

if [ -z "$SSH_PUBLIC_KEY" ] && [ -s /root/.ssh/authorized_keys ]; then
  echo "==> Taking SSH key from root's authorized_keys"
  SSH_PUBLIC_KEY="$(cat /root/.ssh/authorized_keys)"
fi

if [ -z "$SSH_PUBLIC_KEY" ]; then
  echo "No SSH key found in /root/.ssh/authorized_keys and SSH_PUBLIC_KEY is unset." >&2
  echo "Re-run as: SSH_PUBLIC_KEY='ssh-ed25519 AAAA... deployer' bash $0" >&2
  exit 1
fi

echo "==> Creating $TARGET_USER"
if ! id "$TARGET_USER" >/dev/null 2>&1; then
  adduser --disabled-password --gecos "" "$TARGET_USER"
fi
usermod -aG sudo "$TARGET_USER"

echo "==> Installing authorized_keys for $TARGET_USER"
install -d -m 0700 -o "$TARGET_USER" -g "$TARGET_USER" "/home/$TARGET_USER/.ssh"
printf '%s\n' "$SSH_PUBLIC_KEY" > "/home/$TARGET_USER/.ssh/authorized_keys"
chown "$TARGET_USER:$TARGET_USER" "/home/$TARGET_USER/.ssh/authorized_keys"
chmod 0600 "/home/$TARGET_USER/.ssh/authorized_keys"

echo "==> Granting passwordless sudo"
printf '%s ALL=(ALL) NOPASSWD:ALL\n' "$TARGET_USER" > "/etc/sudoers.d/$TARGET_USER"
chmod 0440 "/etc/sudoers.d/$TARGET_USER"
visudo -cf "/etc/sudoers.d/$TARGET_USER"

cat <<EOF

==> Done. Verify from your workstation before applying Terraform:

      ssh $TARGET_USER@<HOST_IPv4> 'sudo -n true && echo ok'

    Then, from the repo root:

      ./resources/terraform/manage.sh auto-drive-staging init
      ./resources/terraform/manage.sh auto-drive-staging plan
      ./resources/terraform/manage.sh auto-drive-staging apply

    When you authenticate to the rescue system with an SSH key, installimage
    disables the root password and password-based root SSH on the installed
    system. Root login by key is still permitted until the bootstrap Terraform
    runs sets PermitRootLogin no. Check the current state with:

      sudo sshd -T | grep -E '^(permitrootlogin|passwordauthentication) '
EOF
