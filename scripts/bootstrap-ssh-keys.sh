#!/usr/bin/env bash
# Create the ubuntu user and install Ved's and Jim's SSH keys on a fresh
# Hetzner install. Run as root before terraform. Idempotent.
#
# Usage: sudo ./bootstrap-ssh-keys.sh
# To override a key, sudo needs it on the command line, quoted because a key
# contains spaces:
#   sudo VED_KEY='ssh-ed25519 AAAA... comment' ./bootstrap-ssh-keys.sh
#
# Hetzner injects no keys at create, so the Robot install call must also pass
# both fingerprints. It is a form-urlencoded POST, and dist is required:
#   POST /boot/{id}/linux
#   dist=Ubuntu+22.04.2+LTS+base&lang=en&authorized_key[]=70:60:3e:d8:5e:47:a5:f7:8f:5e:ef:b4:7d:83:24:9b&authorized_key[]=8f:af:b4:46:b2:42:44:cf:53:84:a8:c1:81:16:a9:ef
set -euo pipefail

umask 077
export PATH=/usr/sbin:/usr/bin:/sbin:/bin
unset BASH_ENV ENV

VED_KEY="${VED_KEY-ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAINLPUQzkb6MpLjedT3fuv+UKTggfiZaJskQdIHIrXkFE 7549475+vedhavyas@users.noreply.github.com}"
JIM_KEY="${JIM_KEY-ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIFNqdmHh9rd+qGVDBRM5ds3dcAHopLpYlLPvp6eztoqW}"

fail() {
  echo "bootstrap-ssh-keys: $*" >&2
  exit 1
}

if [ "$(id -u)" -ne 0 ]; then
  fail "must run as root"
fi

validate_key() {
  local name=$1 key=$2 type b64 tmp size type_len material_len b1 b2 b3 b4

  case $key in
    *$'\n'* | *$'\r'*) fail "$name contains a line break" ;;
  esac

  read -r type b64 _ <<<"$key"
  case $type in
    ssh-ed25519 | ssh-rsa | ecdsa-sha2-nistp256 | ecdsa-sha2-nistp384 | \
      ecdsa-sha2-nistp521 | sk-ssh-ed25519@openssh.com | \
      sk-ecdsa-sha2-nistp256@openssh.com) ;;
    *) fail "$name is missing or has an unsupported key type" ;;
  esac

  case $b64 in
    '' | *[!A-Za-z0-9+/=]*) fail "$name has invalid key material" ;;
  esac
  [ $((${#b64} % 4)) -eq 0 ] || fail "$name has invalid key material"

  tmp=$(mktemp)
  if ! printf '%s' "$b64" | base64 -d >"$tmp" 2>/dev/null; then
    rm -f "$tmp"
    fail "$name has invalid key material"
  fi

  size=$(wc -c <"$tmp")
  read -r b1 b2 b3 b4 < <(od -An -tu1 -N4 "$tmp")
  type_len=$((b1 * 16777216 + b2 * 65536 + b3 * 256 + b4))
  if [ "$type_len" -ne "${#type}" ] || [ "$size" -lt $((8 + type_len)) ]; then
    rm -f "$tmp"
    fail "$name does not decode to an SSH public key"
  fi
  if [ "$(dd if="$tmp" bs=1 skip=4 count="$type_len" 2>/dev/null)" != "$type" ]; then
    rm -f "$tmp"
    fail "$name does not decode to an SSH public key"
  fi
  read -r b1 b2 b3 b4 < <(od -An -tu1 -j $((4 + type_len)) -N4 "$tmp")
  material_len=$((b1 * 16777216 + b2 * 65536 + b3 * 256 + b4))
  if [ "$material_len" -lt 1 ] || [ "$size" -lt $((8 + type_len + material_len)) ]; then
    rm -f "$tmp"
    fail "$name does not decode to an SSH public key"
  fi
  rm -f "$tmp"

  if command -v ssh-keygen >/dev/null 2>&1; then
    tmp=$(mktemp)
    printf '%s\n' "$key" >"$tmp"
    if ! ssh-keygen -l -f "$tmp" >/dev/null 2>&1; then
      rm -f "$tmp"
      fail "$name is not a valid SSH public key"
    fi
    rm -f "$tmp"
  fi
}

# Unset falls back to the default above; an explicitly empty override stays
# empty so the check fails loudly instead of silently installing the default.
for name in VED_KEY JIM_KEY; do
  validate_key "$name" "${!name}"
done

if ! id ubuntu >/dev/null 2>&1; then
  useradd -m -s /bin/bash -G sudo ubuntu
fi

# The terraform provisioner runs sudo commands non-interactively, so ubuntu
# needs passwordless sudo.
install -d -m 0755 -o root -g root /etc/sudoers.d
printf '%s\n' 'ubuntu ALL=(ALL) NOPASSWD:ALL' > /etc/sudoers.d/90-ubuntu
chmod 0440 /etc/sudoers.d/90-ubuntu

ubuntu_home=$(getent passwd ubuntu | cut -d: -f6) || ubuntu_home=
[ -n "$ubuntu_home" ] || fail "cannot resolve ubuntu's home directory"
ubuntu_uid=$(id -u ubuntu)
ubuntu_gid=$(id -g ubuntu)
install -d -m 0700 -o root -g root /root/.ssh
install -d -m 0700 -o "$ubuntu_uid" -g "$ubuntu_gid" "$ubuntu_home/.ssh"

add_key() {
  local file=$1 key=$2 type b64 status=0
  read -r type b64 _ <<<"$key"
  touch "$file"
  awk -v t="$type" -v b="$b64" '$1 == t && $2 == b { found = 1 } END { exit(found ? 0 : 1) }' "$file" || status=$?
  case $status in
    0) return 0 ;;
    1) ;;
    *) fail "cannot read $file" ;;
  esac
  # Robot may leave the file without a trailing newline; without one the
  # key would fuse onto the last line.
  if [ -s "$file" ] && [ -n "$(tail -c 1 -- "$file")" ]; then
    printf '\n' >>"$file"
  fi
  printf '%s\n' "$key" >>"$file"
}

for key in "$VED_KEY" "$JIM_KEY"; do
  add_key /root/.ssh/authorized_keys "$key"
  add_key "$ubuntu_home/.ssh/authorized_keys" "$key"
done

chown root:root /root/.ssh/authorized_keys
chmod 0600 /root/.ssh/authorized_keys
chown "$ubuntu_uid:$ubuntu_gid" "$ubuntu_home/.ssh/authorized_keys"
chmod 0600 "$ubuntu_home/.ssh/authorized_keys"
