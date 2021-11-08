# General Considerations and "Rules".

Basic but not less important considerations.

## Resource definitions.

We use terraform to deploy resources using main branch, to keep track of the last changes.

- Droplet naming: The resource names are defined in the terraform files. Follow the convention as the naming scripts handle the full string to be used.

- Droplet region: Follow the region used in the terraform files. As we share some resources (Like downloaded blocks data for relayer archive), we need to use the same region, this way we can copy data with scp really fast.

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
