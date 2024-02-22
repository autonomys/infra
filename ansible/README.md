# Subspace Infrastructure Ansible Deployments

This README provides an overview and guidance on how to use the provided Ansible playbooks. The playbook are designed to automate specific tasks in subspace infrastructure for stateless deployments

## Overview

This playbook includes tasks necessary for setting up and configuring a the network(s) server environment. It includes roles for setting up network nodes, installing necessary packages, permissioned users, web server Nginx, monitoring, and configuring firewall settings.

## Prerequisites

- Ansible 2.9 or higher installed on your control node.
- SSH access to your target nodes.
- Target nodes should have Python installed.

## Getting Started

1. **Install Ansible**: If you haven't already installed Ansible on your control machine (the machine that executes the playbook), follow the instructions [here](https://docs.ansible.com/ansible/latest/installation_guide/intro_installation.html).

2. **Configure Inventory**: Edit the `hosts.yml` file to list your server IPs or hostnames under the appropriate sections. You can also use an inventory.ini file

   ```yaml
   hetzner:
     hosts:
       192.168.0.1:
       ansible_ssh_user: root
       ansible_ssh_private_key_file: ~/.ssh/key
   ```

   ```ini
   [gemini-3g]
   192.168.1.2
   192.168.1.3
   ```

3. **Set Variables**: Review and update the variables in the `group_vars/*entity*.yml` or vars.yml file to match your environment and requirements.

4. **SSH Keys**: Ensure your SSH keys are set up for connecting to the target machines. See Ansible's [documentation](https://docs.ansible.com/ansible/latest/user_guide/connection_details.html#ssh-key-setup) for more details.

## Running the Playbook

Run the playbook using the following command:

```bash
ansible-playbook -i hosts.yml main.yml
```

5. **Enviroment files**: The env files declared in the variables i.e `env.bootstrap` should be placed in the `**/files` directory in the same path as the docker compose file and not committed into the repository.

## Playbook Structure

- **`main.yml`**: This is the main playbook file that includes various roles.
- **`hosts.yml`**: Inventory file where you define your groups and servers.
- **`roles/`**: Directory containing different roles like web server setup, firewall configuration, etc.
- **`**/group_vars/\*.yml`** OR **/vars.yml: File containing variables used in the playbook.

## Roles Included

- **ephemeral-devnets**: Sets up an ephemeral devnet network
- **network**: Sets up a testnet network i.e gemini-3x
- **setup-users**: Adds users ssh keys to the server(s)
- **server-setup**: Various roles to bootstrap the server and firewall security

## Customization

- You can customize the playbook by editing the variables or adding new roles/tasks. Make sure to test the playbook in a development environment before running it in production.

## Troubleshooting

- If you encounter any issues, check the Ansible error messages for guidance.
- Ensure all target machines are accessible via SSH from the control node.
- Verify all required software is installed on the target machines.

```

```
