# Auto Drive — Staging Environment

This environment is planned but not yet configured. It will use the shared
`modules/auto-drive` module with staging-specific settings.

## Planned structure

```
auto-drive-staging/
├── backend.tf          # Terraform Cloud workspace (new workspace needed)
├── main.tf             # Module call with staging values
├── providers.tf        # Provider config (may include non-AWS providers)
├── variables.tf        # Staging-specific variables
├── versions.tf         # Provider version constraints
├── outputs.tf          # Re-exported module outputs
├── common.auto.tfvars  # Secrets (gitignored, stored in Infisical)
└── user.auto.tfvars    # Local overrides (gitignored)
```

## Notes

- The staging environment may use different providers beyond AWS (e.g. for
  non-AWS hosting). Provider configuration belongs here, not in the module.
- The old taurus testnet instances were previously co-located in the production
  config but have been retired along with the taurus network.
- A new Terraform Cloud workspace will need to be created in the `subspace-sre`
  org with local execution mode.
