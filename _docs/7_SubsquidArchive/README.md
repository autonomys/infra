# Subsquid archive

Subspace Network maintains [Subsquid Archive](https://docs.subsquid.io/archives/) in order to store raw chain data in a normalized way and expose it using GraphQL endpoint

## Docker and Docker Compose setup
Install Docker:

The latest docker docs can be found [here](https://docs.docker.com/engine/install/ubuntu/#set-up-the-repository) to help install docker and docker compose

Remove old versions of docker first:
```bash
sudo apt-get remove docker docker-engine docker.io containerd runc
```

Install new versions of docker, containerd and docker compose:
```bash
sudo apt-get update
sudo apt-get install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
```

## Create Subsquid Archive
Create a Subsquid Archive setup using Docker Compose:
```bash
mkdir subsquid-archive
cd subsquid-archive
touch docker-compose.yml
```

Sample [docker-compose.yml](docker-compose.yml) can be used as a reference. It will require running a local Subspace node to read data from as well as Subsquid-specific services (DB, ingest, gateway and explorer)

> Make sure you provide: 
> - volume name for DB and node data
> - node snapshot release (for example `gemini-2a-2022-oct-06`, latest release can be found [here](https://github.com/subspace/subspace/pkgs/container/node))
> - chain (for example `gemini-2a`)
> - node name (in order to find your node on [Subspace Telemetry](https://telemetry.subspace.network/))

Pull fresh images and start containers:
```bash
docker compose pull
docker compose up -d
```

## Nginx setup and SSL certificate
Install Nginx:
```bash
sudo apt update
sudo apt install nginx
```

Sample [Nginx config](archive.subspace.network) can be used as a reference.
> Note: it requires including `/etc/nginx/cors-settings.conf`, which can be found [here](cors-settings.conf)

It exposes Archive Graphql endpoint `/api` (consumed by squids) as well as Graphql Explorer at `/graphql` (UI for exploration and debugging)

Install Certbot:
```bash
sudo apt install certbot python3-certbot-nginx --no-install-recommends
```

Obtain an SSL certificate:
```bash
sudo certbot --nginx -d archive.subspace.network
```
