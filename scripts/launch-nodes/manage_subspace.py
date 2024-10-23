import os
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
        logger.error(f"Failed to run command: {e}")
        raise

def modify_env_file(client, subspace_dir, release_version, genesis_hash=None, pot_external_entropy=None, plot_size=None, cache_percentage=None, network=None):
    """Modify the .env file to update various settings."""
    try:
        commands = [
            f"sed -i '/^DOCKER_TAG=/c\\DOCKER_TAG={release_version}' {subspace_dir}/.env",
            f"sed -i '/^GENESIS_HASH=/c\\GENESIS_HASH={genesis_hash}' {subspace_dir}/.env" if genesis_hash else "",
            f"sed -i '/^POT_EXTERNAL_ENTROPY=/c\\POT_EXTERNAL_ENTROPY={pot_external_entropy}' {subspace_dir}/.env" if pot_external_entropy else "",
            f"sed -i '/^PLOT_SIZE=/c\\PLOT_SIZE={plot_size}' {subspace_dir}/.env" if plot_size else "",
            f"sed -i '/^CACHE_PERCENTAGE=/c\\CACHE_PERCENTAGE={cache_percentage}' {subspace_dir}/.env" if cache_percentage else "",
            f"sed -i '/^NETWORK_NAME=/c\\NETWORK_NAME={network}' {subspace_dir}/.env" if network else ""
        ]
        for command in filter(bool, commands):
            stdout, stderr = run_command(client, command)
            if stderr:
                logger.error(f"Error modifying .env file with command: {command}, error: {stderr}")
                raise Exception(f"Error modifying .env file: {stderr}")
            else:
                logger.info(f"Successfully executed command: {command}")
    except Exception as e:
        logger.error(f"Failed to modify .env file: {e}")
        raise

    except Exception as e:
        logger.error(f"Failed to modify .env file: {e}")
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

def docker_compose_restart(client, subspace_dir, docker_tag=None):
    """Run sudo docker compose restart in the subspace directory."""
    try:
        # Modify .env file if a new DOCKER_TAG is provided
        if docker_tag:
            logger.info(f"Updating DOCKER_TAG to {docker_tag} in {subspace_dir}/.env")
            modify_env_file(client, subspace_dir, release_version=docker_tag)

        # Restart the containers
        restart_cmd = f'cd {subspace_dir} && sudo docker compose restart'
        logger.info(f"Running sudo docker compose restart in {subspace_dir}")
        run_command(client, restart_cmd)

    except Exception as e:
        logger.error(f"Failed to run sudo docker compose restart: {e}")
        raise

def docker_cleanup(client, subspace_dir):
    """Stop all containers, prune unused containers and images in the subspace directory."""
    try:
        # Check if there are running containers
        check_running_containers_cmd = f'cd {subspace_dir} && sudo docker ps -q'
        stdout, _ = run_command(client, check_running_containers_cmd)

        if stdout.strip():  # Only run stop command if there are running containers
            stop_containers_cmd = f'cd {subspace_dir} && sudo docker stop $(sudo docker ps -q)'
            logger.info(f"Stopping running containers in {subspace_dir}")
            run_command(client, stop_containers_cmd)
        else:
            logger.info("No running containers found to stop.")

        # Prune unused containers and images
        prune_cmd = f'cd {subspace_dir} && sudo docker container prune -f && sudo docker image prune -a -f'
        logger.info(f"Pruning unused containers and images in {subspace_dir}")
        run_command(client, prune_cmd)

    except Exception as e:
        logger.error(f"Failed to run Docker cleanup commands: {e}")
        raise

def docker_compose_up(client, subspace_dir):
    """Run sudo docker compose up -d in the subspace directory."""
    try:
        command = f'cd {subspace_dir} && sudo docker compose up -d'
        logger.info(f"Running sudo docker compose up -d in {subspace_dir}")
        run_command(client, command)
    except Exception as e:
        logger.error(f"Failed to run sudo docker compose up -d: {e}")
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

def handle_node(client, node, subspace_dir, release_version, pot_external_entropy=None,
                plot_size=None, cache_percentage=None, network=None, prune=False, restart=False,
                update_genesis_hash=True, genesis_hash=None):
    """Generic function to handle different node types with specified actions."""
    try:
        if prune:
            docker_cleanup(client, subspace_dir)
        elif restart:
            docker_compose_restart(client, subspace_dir)
        else:
            docker_compose_down(client, subspace_dir)

            # Update .env file with the appropriate parameters
            modify_env_file(client, subspace_dir, release_version,
                            pot_external_entropy=pot_external_entropy,
                            plot_size=plot_size,
                            cache_percentage=cache_percentage,
                            network=network,
                            genesis_hash=genesis_hash if update_genesis_hash else None)

            docker_compose_up(client, subspace_dir)

    except Exception as e:
        logger.error(f"Error handling node {node['host']}: {e}")
    finally:
        if client:
            client.close()

def main():
    parser = argparse.ArgumentParser(description="Manage Subspace nodes via SSH")
    parser.add_argument('--config', required=True, help='Path to the TOML config file')
    parser.add_argument('--network', required=True, help='Network to update in the .env file, i.e devnet, gemini-3h, taurus')
    parser.add_argument('--release_version', required=True, help='Release version to update in the .env file')
    parser.add_argument('--subspace_dir', default='/home/ubuntu/subspace', help='Path to the Subspace directory')
    parser.add_argument('--pot_external_entropy', help='POT_EXTERNAL_ENTROPY value for all nodes')
    parser.add_argument('--log_level', default='INFO', help='Set the logging level (DEBUG, INFO, WARNING, ERROR)')
    parser.add_argument('--no-timekeeper', action='store_true', help='Disable launching of the timekeeper node')
    parser.add_argument('--prune', action='store_true', help='Stop containers and destroy the Docker images')
    parser.add_argument('--restart', action='store_true', help='Restart the network without wiping the data')
    parser.add_argument('--plot-size', help='Set plot size on the farmer, i.e 10G')
    parser.add_argument('--cache-percentage', help='Set the cache percentage on the farmer, i.e 10')
    args = parser.parse_args()

    # Set logging level based on user input
    log_level = args.log_level.upper()
    logging.getLogger().setLevel(log_level)

    # Read configuration from the TOML file
    with open(args.config, 'rb') as f:
        config = tomli.load(f)

    bootstrap_node = config['bootstrap_node']
    farmer_nodes = [node for node in config['farmer_rpc_nodes'] if node['type'] == 'farmer']
    rpc_nodes = [node for node in config['farmer_rpc_nodes'] if node['type'] == 'rpc']
    timekeeper_node = config['timekeeper']

    # Step 1: Handle the timekeeper node, if enabled
    if not args.no_timekeeper and timekeeper_node:
        try:
            logger.info(f"Connecting to timekeeper node {timekeeper_node['host']}...")
            client = ssh_connect(timekeeper_node['host'], timekeeper_node['user'], timekeeper_node['ssh_key'])
            handle_node(client, timekeeper_node, args.subspace_dir, args.release_version, pot_external_entropy=args.pot_external_entropy, network=args.network, prune=args.prune, restart=args.restart)
        except Exception as e:
            logger.error(f"Error handling timekeeper node: {e}")
        finally:
            if client:
                client.close()
    else:
        logger.info("Timekeeper handling is disabled or not specified.")

    # Step 2: Handle farmer nodes
    for node in farmer_nodes:
        try:
            logger.info(f"Connecting to farmer node {node['host']}...")
            client = ssh_connect(node['host'], node['user'], node['ssh_key'])
            handle_node(client, node, args.subspace_dir, args.release_version, pot_external_entropy=args.pot_external_entropy, network=args.network, plot_size=args.plot_size, cache_percentage=args.cache_percentage, prune=args.prune, restart=args.restart)
        except Exception as e:
            logger.error(f"Error handling farmer node {node['host']}: {e}")
        finally:
            if client:
                client.close()

    # Step 3: Handle RPC nodes
    protocol_version_hash = None
    for node in rpc_nodes:
        try:
            logger.info(f"Connecting to RPC node {node['host']}...")
            client = ssh_connect(node['host'], node['user'], node['ssh_key'])

            # Handle node operations (prune/restart will be managed here)
            handle_node(client, node, args.subspace_dir, args.release_version,
                        pot_external_entropy=args.pot_external_entropy,
                        network=args.network,
                        prune=args.prune,
                        restart=args.restart)

            # Skip protocol version extraction if prune or restart is specified
            if args.prune or args.restart:
                logger.info(f"Skipping protocol version extraction for RPC node {node['host']} due to prune/restart.")
                continue

            # If this is an RPC node, wait and then extract protocol version hash
            logger.info(f"Waiting for RPC node {node['host']} to start...")
            sleep(30)  # Adjust sleep time as necessary

            # Attempt to grep the protocol version from logs
            protocol_version_hash = grep_protocol_version(client)

            if not protocol_version_hash:
                logger.error(f"Failed to retrieve protocol version hash on RPC node {node['host']}")
                continue
        except Exception as e:
            logger.error(f"Error handling RPC node {node['host']}: {e}")
        finally:
            if client:
                client.close()

    # Step 4: Handle the bootstrap node, using the protocol version hash if available
    try:
        logger.info(f"Connecting to the bootstrap node {bootstrap_node['host']}...")
        client = ssh_connect(bootstrap_node['host'], bootstrap_node['user'], bootstrap_node['ssh_key'])

        # Warn about missing protocol version hash before proceeding with the bootstrap node update
        if not protocol_version_hash:
            logger.warning("Protocol version hash not found; proceeding with bootstrap node without genesis_hash update.")

        # Handle node operations with update_genesis_hash set to True
        handle_node(client, bootstrap_node, args.subspace_dir, args.release_version,
                    pot_external_entropy=args.pot_external_entropy,
                    network=args.network,
                    prune=args.prune,
                    restart=args.restart,
                    update_genesis_hash=True,  # Always update genesis hash
                    genesis_hash=protocol_version_hash)

    except Exception as e:
        logger.error(f"Error handling bootstrap node: {e}")
    finally:
        if client:
            client.close()


if __name__ == '__main__':
    main()
