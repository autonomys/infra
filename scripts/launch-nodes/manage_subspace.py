import paramiko
import argparse
import tomli
import re
import logging
import colorlog
from time import sleep

# Configure logging with colorlog
handler = colorlog.StreamHandler()
handler.setFormatter(colorlog.ColoredFormatter(
    '%(log_color)s%(asctime)s - %(levelname)s - %(message)s',
    log_colors={
        'DEBUG': 'cyan',
        'INFO': 'green',
        'WARNING': 'yellow',
        'ERROR': 'red',
        'CRITICAL': 'bold_red',
    }
))
logger = colorlog.getLogger(__name__)
logger.addHandler(handler)
logger.setLevel(logging.INFO)

def ssh_connect(host, user, key_file):
    """Establish an SSH connection to a server."""
    try:
        client = paramiko.SSHClient()
        client.set_missing_host_key_policy(paramiko.AutoAddPolicy())
        client.connect(hostname=host, username=user, key_filename=key_file)
        logger.info(f"Connected to {host}")
        return client
    except Exception as e:
        logger.error(f"Failed to connect to {host}: {e}")
        raise

def run_command(client, command):
    """Run a command over SSH and return the output."""
    try:
        stdin, stdout, stderr = client.exec_command(command)
        output = stdout.read().decode('utf-8')
        error = stderr.read().decode('utf-8')

        # Treat Docker status updates as INFO instead of ERROR
        if error:
            if any(keyword in error for keyword in ["Stopping", "Stopped", "Creating", "Started", "Removing", "Removed"]):
                logger.info(f"Command output: {error.strip()}")
            else:
                logger.error(f"Error running command: {error.strip()}")
        return output, error
    except Exception as e:
        logger.error(f"Failed to run command: {command}: {e}")
        raise

def docker_compose_down(client, subspace_dir):
    """Run sudo docker compose down -v in the subspace directory."""
    try:
        command = f'cd {subspace_dir} && sudo docker compose down -v'
        logger.info(f"Running sudo docker compose down -v in {subspace_dir}")
        run_command(client, command)
    except Exception as e:
        logger.error(f"Failed to run sudo docker compose down -v: {e}")
        raise

def modify_env_file(client, subspace_dir, release_version, genesis_hash=None, pot_external_entropy=None):
    """Modify the .env file to update the Docker tag and optionally the Genesis Hash and POT_EXTERNAL_ENTROPY."""
    env_file = f'{subspace_dir}/.env'

    try:
        sftp = client.open_sftp()
        with sftp.open(env_file, 'r') as f:
            env_data = f.readlines()

        pot_entropy_found = False

        # Modify the Docker tag, Genesis hash, and POT_EXTERNAL_ENTROPY
        with sftp.open(env_file, 'w') as f:
            for line in env_data:
                if line.startswith('DOCKER_TAG='):
                    logger.debug(f"Writing DOCKER_TAG={release_version}")
                    f.write(f'DOCKER_TAG={release_version}\n')
                elif genesis_hash and line.startswith('GENESIS_HASH='):
                    logger.debug(f"Writing GENESIS_HASH={genesis_hash}")
                    f.write(f'GENESIS_HASH={genesis_hash}\n')
                elif pot_external_entropy and line.startswith('POT_EXTERNAL_ENTROPY='):
                    f.write(f'POT_EXTERNAL_ENTROPY={pot_external_entropy}\n')
                    pot_entropy_found = True
                else:
                    f.write(line)

            # If POT_EXTERNAL_ENTROPY was not found, append it
            if pot_external_entropy and not pot_entropy_found:
                logger.debug(f"Writing POT_EXTERNAL_ENTROPY={pot_external_entropy}")
                f.write(f'POT_EXTERNAL_ENTROPY={pot_external_entropy}\n')

        logger.info(f"Modified .env file in {env_file}")
    except Exception as e:
        logger.error(f"Failed to modify .env file: {e}")
        raise

def grep_protocol_version(client, retries=5, interval=30):
    """Grep the logs to find the protocol version and extract the hash."""
    logs_command = 'sudo docker logs --tail 100 subspace-archival-node-1 | grep "protocol_version="'

    for attempt in range(retries):
        try:
            stdout, stderr = run_command(client, logs_command)
            match = re.search(r'protocol_version=/subspace/2/([a-f0-9]+)', stdout)
            if match:
                logger.info(f"Protocol version hash found: {match.group(1)}")
                return match.group(1)
            else:
                logger.warning(f"Protocol version hash not found. Attempt {attempt + 1} of {retries}")
        except Exception as e:
            logger.error(f"Error grepping protocol version: {e}")

        if attempt < retries - 1:
            logger.info(f"Retrying in {interval} seconds...")
            sleep(interval)

    logger.error("Failed to retrieve protocol version hash after retries.")
    return None

def docker_compose_up(client, subspace_dir):
    """Run sudo docker compose up -d in the subspace directory."""
    try:
        command = f'cd {subspace_dir} && sudo docker compose up -d'
        logger.info(f"Running sudo docker compose up -d in {subspace_dir}")
        run_command(client, command)
    except Exception as e:
        logger.error(f"Failed to run sudo docker compose up -d: {e}")
        raise

def main():
    # Parse command line arguments
    parser = argparse.ArgumentParser(description="Manage Subspace nodes via SSH")
    parser.add_argument('--config', required=True, help='Path to the TOML config file')
    parser.add_argument('--release_version', required=True, help='Release version to update in the .env file')
    parser.add_argument('--subspace_dir', default='/home/ubuntu/subspace', help='Path to the Subspace directory (default: /home/ubuntu/subspace)')
    parser.add_argument('--pot_external_entropy', help='POT_EXTERNAL_ENTROPY value for the timekeeper node')
    parser.add_argument('--log_level', default='INFO', help='Set the logging level (DEBUG, INFO, WARNING, ERROR)')
    args = parser.parse_args()

    # Set logging level based on user input
    log_level = args.log_level.upper()
    logging.getLogger().setLevel(log_level)

    logger.debug(f"Received POT_EXTERNAL_ENTROPY: {args.pot_external_entropy}")

    # Read configuration from the TOML file using tomli
    with open(args.config, 'rb') as f:
        config = tomli.load(f)

    bootstrap_node = config['bootstrap_node']
    farmer_rpc_nodes = config['farmer_rpc_nodes']
    timekeeper_node = config['timekeeper']

    release_version = args.release_version
    subspace_dir = args.subspace_dir

    # Step 1: sudo docker compose down -v on all farmer and RPC nodes
    for node in farmer_rpc_nodes:
        client = None  # Initialize the client variable
        try:
            logger.info(f"Connecting to {node['host']} for sudo docker compose down -v...")
            client = ssh_connect(node['host'], node['user'], node['ssh_key'])

            # Run sudo docker compose down -v
            docker_compose_down(client, subspace_dir)

            # Close connection after shutdown
            client.close()
        except Exception as e:
            logger.error(f"Error during sudo docker compose down -v on {node['host']}: {e}")
        finally:
            if client:
                client.close()
                logger.debug(f"Closed connection for node {node['host']}")

    # Step 2: Update .env and start sudo docker compose for RPC and Farmer nodes
    protocol_version_hash = None
    for node in farmer_rpc_nodes:
        client = None  # Initialize the client variable
        try:
            logger.info(f"Connecting to {node['host']}...")
            client = ssh_connect(node['host'], node['user'], node['ssh_key'])

            # Modify the .env file
            modify_env_file(client, subspace_dir, release_version)

            # Start sudo docker compose up -d
            docker_compose_up(client, subspace_dir)

            # If this is the RPC node, grep the logs for protocol version hash
            if node['type'] == 'rpc':
                logger.info(f"Waiting for the RPC node to start...")
                sleep(30)  # Adjust sleep time as necessary

                logger.info(f"Grep protocol version from logs on {node['host']}...")
                protocol_version_hash = grep_protocol_version(client)

                if not protocol_version_hash:
                    logger.error(f"Failed to retrieve protocol version hash on {node['host']}")
                    continue

            client.close()
        except Exception as e:
            logger.error(f"Error during update and start on {node['host']}: {e}")
        finally:
            if client:
                client.close()
                logger.debug(f"Closed connection for node {node['host']}")

    if timekeeper_node:
        client = None  # Initialize the client variable
        if args.pot_external_entropy:
            try:
                logger.info(f"Connecting to the timekeeper node {timekeeper_node['host']}...")
                client = ssh_connect(timekeeper_node['host'], timekeeper_node['user'], timekeeper_node['ssh_key'])

                # Modify the .env file with the POT_EXTERNAL_ENTROPY value
                logger.debug(f"Modifying .env file with POT_EXTERNAL_ENTROPY={args.pot_external_entropy}")
                modify_env_file(client, subspace_dir, release_version, pot_external_entropy=args.pot_external_entropy)

                # Start the timekeeper node
                docker_compose_up(client, subspace_dir)

                logger.info("Timekeeper node started with the updated POT_EXTERNAL_ENTROPY value.")
            except Exception as e:
                logger.error(f"Error during timekeeper node update: {e}")
            finally:
                if client:
                    client.close()
                    logger.debug(f"Closed connection to timekeeper node {timekeeper_node['host']}")
        else:
            logger.warning(f"POT_EXTERNAL_ENTROPY not provided for the timekeeper node, skipping update.")

    # Step 3: SSH into the bootstrap node and update GENESIS_HASH, then start it
    if protocol_version_hash:
        client = None  # Initialize the client variable
        try:
            logger.info(f"Connecting to the bootstrap node {bootstrap_node['host']} for sudo docker compose down -v...")
            client = ssh_connect(bootstrap_node['host'], bootstrap_node['user'], bootstrap_node['ssh_key'])

            # Run sudo docker compose down -v for the bootstrap node
            docker_compose_down(client, subspace_dir)

            # Modify .env with the new GENESIS_HASH
            modify_env_file(client, subspace_dir, release_version, genesis_hash=protocol_version_hash)

            # Start the bootstrap node
            docker_compose_up(client, subspace_dir)

            client.close()
            logger.info("Bootstrap node started with the updated Genesis Hash.")
        except Exception as e:
            logger.error(f"Error during bootstrap node update: {e}")
        finally:
            if client:
                client.close()
    else:
        logger.error("Protocol version hash not found, skipping bootstrap node start.")

if __name__ == '__main__':
    main()
