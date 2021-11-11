# General Considerations.

## Resource definitions.

We use Terraform to deploy resources using the main branch and keep track of the last changes.

- Naming: Resource names follow a simple format. Just be aware of this to have a consistent and easy way to identify them.

- Region: Usually will set the same region for all resources in the same environment.

## Admin considerations.

Droplets must share this minimial settings, as an Admin or Owner you are responsible for the security of the resources. This are normal considerations but just to be clear.

- Do not use root user.
- Sudo user for aministrator.
- Sudo user for resource owner/responsable.
- Sudo user for team members who requiere.
- SSH key auth as only method.
- Password auth disabled on all droplets.
  (/etc/ssh/sshd_config) PasswordAuthentication no
  (/etc/ssh/sshd_config) PermitRootLogin no, if we want to be strict.

_Feel free to add another best practices for users and authentication._

### Droplet system settings.

- Use Ubuntu 20.04 LTS, or latest LTS version.
