
# Subspace Node Manager

This script manages the deployment of Subspace nodes (RPC, Farmer, and Bootstrap nodes) on multiple servers using SSH. It updates the `.env` file with the specified release version and coordinates the startup sequence to ensure that RPC and Farmer nodes are started first. The Bootstrap node is updated last with the correct `GENESIS_HASH` and then started.

## Features

- SSH into multiple servers defined in a TOML configuration file.
- Modify `.env` files in the Subspace directory with a new release version and update `GENESIS_HASH`.
- Restart Subspace nodes using `docker-compose down -v` and `docker-compose up -d`.
- Retrieve the `protocol_version` hash from the RPC node logs and use it to update the Bootstrap node.
- Ensure proper start order (RPC and Farmer nodes first, Bootstrap node last).

## Prerequisites

- **Python 3.x** installed on your local machine.
- The following Python libraries (installed via the provided `install_dependencies.sh` script):
  - `paramiko` for SSH connections.
  - `toml` for reading the configuration file.
- SSH access to the remote servers where the Subspace nodes are running.
- Ensure the remote servers have Docker and Docker Compose installed.

## Installation

### Step 1: Install Dependencies

1. Clone the repository or download the Python script and associated files.
2. Use the provided `install_dependencies.sh` script to install the required Python packages in a virtual environment.

```bash
chmod +x install_dependencies.sh
./install_dependencies.sh
```

This will create a virtual environment (`subspace_env`) and install the required packages: `paramiko` and `toml`.

### Step 2: Activate the Virtual Environment

Activate the virtual environment where the dependencies are installed:

```bash
source subspace_env/bin/activate
```

### Step 3: Prepare Configuration

Create a TOML configuration file (`nodes.toml`) with details for your Bootstrap, RPC, and Farmer nodes. The file should look like this:

```toml
# TOML file containing server details

[bootstrap_node]
host = "bootstrap.example.com"
user = "username"
ssh_key = "/path/to/private/key"

[farmer_rpc_nodes]

[[farmer_rpc_nodes]]
host = "rpc.example.com"
user = "username"
ssh_key = "/path/to/private/key"
type = "rpc"

[[farmer_rpc_nodes]]
host = "farmer.example.com"
user = "username"
ssh_key = "/path/to/private/key"
type = "farmer"
```

- **`bootstrap_node`:** This section defines the Bootstrap node.
- **`farmer_rpc_nodes`:** This section contains the RPC and Farmer nodes. The `type` field specifies whether the node is an RPC node or a Farmer node.

### Step 4: Running the Script

Once the configuration file is ready, make the python script executable and run the Python script with the following command:

```bash
chmod +x manage_subspace.py
python manage_subspace.py --config nodes.toml --release_version gemini-3h-2024-sep-17 --subspace_dir /home/ubuntu/subspace/subspace
```

- `--config`: Path to the TOML configuration file.
- `--release_version`: The release version to be used to update the `DOCKER_TAG` in the `.env` files.
- `--subspace_dir`: Path to the Subspace directory (default: `/home/ubuntu/subspace`).

### Step 5: Deactivate the Virtual Environment

Once the script has run, deactivate the virtual environment:

```bash
deactivate
```

## Logging and Error Handling

The script logs important actions and any errors that occur. The following log levels are used:

- **INFO**: General information about the script's progress (e.g., starting/stopping nodes, modifying files).
- **WARNING**: Warnings about non-critical issues (e.g., retries during protocol version extraction).
- **ERROR**: Errors that prevent successful execution (e.g., failed SSH connections, issues with running commands).

## Retry Mechanism

The script includes a retry mechanism when extracting the `protocol_version` from the RPC node logs. It attempts to grep the log multiple times (default 5 retries) with a delay (default 10 seconds) between attempts.

## License

This project is licensed under the MIT License.

## Troubleshooting

- Ensure you have SSH access to all nodes and that your private key is properly configured.
- Ensure Docker and Docker Compose are installed and configured on the target servers.
- Check your `.env` file permissions to make sure the script can read and write to it.
