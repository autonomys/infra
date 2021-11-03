# General Considerations and "Rules".

A compilation of "rules" to discuss and confirm with the team. Things like auth method to droplets, resources naming format, terraform, deployment requests, deployment policies, deployment administrators, ci/cd and versioning... Maybe basic but not less important things that has been mentioned some times in meets and at some point we need to discuss and define and stop acumulating.

## Resource definitions.

We use terraform to deploy resources using main branch, to keep track of the last changes.

- Droplet naming: The resource names are defined in the terraform files. Follow the convention as the naming scripts handle the full string to be used.

### Authentication.

All our Droplet resources declaration must share this minimial settings:

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

- Use ubuntu 20.04 LTS, or latest LTS ubuntu version.
- Follow the regions indicated by the convention of the team. **(SFO3)**
