# 0xAutonomys Infrastructure

Terraform project for the **0xAutonomys** EC2 instance — an [OpenClaw](https://openclaw.ai) AI agent running on AWS.

## What This Manages

### Automated (Terraform)

| Resource | Description |
|----------|-------------|
| `aws_instance.this` | t3.medium EC2, Ubuntu 24.04 LTS, 20GB gp3 |
| `aws_security_group.this` | SSH ingress (currently open), all egress |
| `aws_eip.this` | Elastic IP for stable public address |

### Automated (cloud-init, first boot only)

The `cloud-init.yaml` configures the OS on first boot:

- Hostname (`0xautonomys`) and timezone (UTC)
- SSH hardening (no root login, no password auth, key-only)
- UFW firewall (deny incoming, allow SSH + all outbound)
- fail2ban (sshd jail, 1h ban, 5 retries)
- Unattended security upgrades (auto-reboot disabled)
- Disable unused services (ModemManager, multipathd, fwupd, packagekit)
- journald log rotation (500MB max, 30 day retention)
- `autonomys` service user with sudoers entry and SSH key
- System Node.js 22 via NodeSource
- Linger enabled for `autonomys` user (systemd user services)

### Not Automated (manual steps after provisioning)

These require interactive setup or contain secrets:

1. **nvm + Node.js 24** — Install under `autonomys` user
2. **OpenClaw** — `npm install -g openclaw && openclaw onboard` (interactive wizard)
3. **`.env` file** — Create at `/home/autonomys/.openclaw/.env` (chmod 600)
4. **systemd override** — Drop-in for EnvironmentFile
5. **openclaw symlink** — `/usr/local/bin/openclaw` -> nvm binary
6. **Telegram pairing** — Via OpenClaw onboarding
7. **Google OAuth** — Client secret JSON at `/home/autonomys/.openclaw/credentials/`
8. **Workspace files** — `SOUL.md`, `HEARTBEAT.md`, skills
9. **Cron job** — Disk usage alert via Telegram (under `ubuntu` user)

## Prerequisites

- Terraform >= 1.5
- AWS credentials with EC2/VPC/EIP permissions
- Terraform Cloud access (org: `subspace-sre`)
- SSH key pair `0xautonomys` already registered in AWS (private key in password manager)

## Setup

### 1. Create Terraform Cloud Workspace

Create a workspace named `0xautonomys` in the `subspace-sre` org. Set execution mode to **Local**.

### 2. Configure Secrets

Create `user.auto.tfvars` with your AWS credentials:

```bash
cp user.auto.tfvars.example user.auto.tfvars
# Edit user.auto.tfvars with your AWS access key, secret key, and subnet ID
```

### 3. Plan and Apply

```bash
terraform init
terraform plan
terraform apply
```

## Post-Provision Manual Steps

After Terraform provisioning (or on an existing instance), complete these steps as the `autonomys` user:

```bash
# SSH in as autonomys
ssh 0xautonomys-agent

# 1. Install nvm
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.7/install.sh | bash
source ~/.bashrc

# 2. Install Node.js 24 (LTS)
nvm install 24

# 3. Install OpenClaw
npm install -g openclaw

# 4. Create the symlink (as ubuntu user, with sudo)
# ssh 0xautonomys
# sudo ln -sf /home/autonomys/.nvm/versions/node/v24.x.x/bin/openclaw /usr/local/bin/openclaw

# 5. Run onboarding (interactive)
openclaw onboard
# - Select gateway mode
# - Configure Telegram channel
# - Set model to anthropic/claude-sonnet-4-6

# 6. Create .env file
cat > ~/.openclaw/.env << 'EOF'
ANTHROPIC_API_KEY=<secret>
TELEGRAM_BOT_TOKEN=<secret>
TELEGRAM_APPROVAL_CHAT_ID=<secret>
AUTO_DRIVE_API_KEY=<secret>
GOOGLE_CLIENT_ID=<secret>
GOOGLE_CLIENT_SECRET=<secret>
EOF
chmod 600 ~/.openclaw/.env

# 7. Add systemd override for EnvironmentFile
mkdir -p ~/.config/systemd/user/openclaw-gateway.service.d
cat > ~/.config/systemd/user/openclaw-gateway.service.d/override.conf << 'EOF'
[Service]
EnvironmentFile=%h/.openclaw/.env
EOF
systemctl --user daemon-reload
systemctl --user restart openclaw-gateway

# 8. Place workspace files
# - ~/.openclaw/workspace/SOUL.md
# - ~/.openclaw/workspace/HEARTBEAT.md
# - ~/.openclaw/workspace/skills/auto-drive/

# 9. Set up cron job (as ubuntu user, not autonomys)
# ssh 0xautonomys
# crontab -e
# Add disk usage alert (see spec for full cron line)

# 10. Google OAuth setup
# Place client_secret_*.json in ~/.openclaw/credentials/
```

## Secrets Reference

These secrets are NOT stored in the repo. They must be provisioned manually:

| Secret | Location | Source |
|--------|----------|--------|
| AWS credentials | `common.auto.tfvars` | Infisical |
| SSH private key | `~/.ssh/0xautonomys.pem` | Password manager |
| `ANTHROPIC_API_KEY` | `.openclaw/.env` | Anthropic console |
| `TELEGRAM_BOT_TOKEN` | `.openclaw/.env` | BotFather |
| `AUTO_DRIVE_API_KEY` | `.openclaw/.env` | Auto Drive |
| `GOOGLE_CLIENT_ID` | `.openclaw/.env` | Google Cloud console |
| `GOOGLE_CLIENT_SECRET` | `.openclaw/.env` | Google Cloud console |
| Google OAuth JSON | `.openclaw/credentials/` | Google Cloud console |

## Validation

Run `validate.sh` to verify the live instance matches the spec:

```bash
./validate.sh              # uses SSH host "0xautonomys"
./validate.sh 0xautonomys  # explicit host
```

This checks OS-level configuration (SSH hardening, UFW, fail2ban, users, Node.js, OpenClaw service, workspace files). Use alongside `terraform plan` which checks AWS-level resources.

## Security Notes

- SSH is currently open to `0.0.0.0/0` because not all operators have static IPs. Security relies on key-only auth + fail2ban.
- Consider AWS Systems Manager Session Manager as an alternative to direct SSH exposure.
- The `.env` file is chmod 600 and owned by the `autonomys` user.
- IMDSv2 is enforced (`http_tokens = "required"`).
