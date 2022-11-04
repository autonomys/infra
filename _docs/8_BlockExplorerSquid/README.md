# Block explorer squid

[Squid](https://docs.subsquid.io/overview/#squids) used for Subspace block explorer. Consumes raw data from the [Archive](./7_SubsquidArchive/README.md) and exposes it using GraphQL endpoint

## Docker and Docker Compose setup
Install Docker:

```bash
sudo apt-get update
sudo apt-get install -y docker.io docker-compose-plugin
```

## Create Block explorer squid
Create a Subsquid Archive setup using Docker Compose:
```bash
mkdir squid-blockexplorer
cd squid-blockexplorer
touch docker-compose.yml
```

Sample [docker-compose.yml](docker-compose.yml) can be used as a reference. It will require running Postgres, Squid processor as well as GraphQL server

> Make sure you provide: 
> - volume name for DB, as well as `DB_NAME` and `DB_PASS`
> - Subsquid archive endpoint (for example `https://archive.subspace.network/api`)
> - Chain RPC enpoint (for example `wss://eu-0.gemini-2a.subspace.network/ws`)

Pull fresh images and start containers:
```bash
docker-compose pull
docker-compose up -d
```

## Nginx setup and SSL certificate
Install Nginx:
```bash
sudo apt update
sudo apt install nginx
```

Sample [Nginx config](blockexplorer.subspace.network) can be used as a reference.

Install Certbot:
```bash
sudo snap install core
sudo snap refresh core
sudo apt remove certbot
sudo snap install --classic certbot
sudo ln -s /snap/bin/certbot /usr/bin/certbot
```

Obtain an SSL certificate:
```bash
sudo certbot --nginx -d archive.subspace.network
```
