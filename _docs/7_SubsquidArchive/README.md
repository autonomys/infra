# Subsquid archive

Subspace Network maintains [Subsquid Archive](https://docs.subsquid.io/archives/) in order to store raw chain data in a normalized way and expose it using GraphQL endpoint

## Docker and Docker Compose setup
Install Docker:

```bash
sudo apt-get update
sudo apt-get install apt-transport-https ca-certificates curl gnupg lsb-release
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
echo \
  "deb [arch=amd64 signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu \
  $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
sudo apt-get update
sudo apt-get install -y docker.io
```

Install Docker Compose:
```bash
sudo curl -L https://github.com/docker/compose/releases/download/2.12.2/docker-compose-`uname -s`-`uname -m` -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose
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
> - volume name for DB and node data (for example `volume_subsquid_subspace`)
> - node snapshot release (for example `gemini-2a-2022-oct-06`, latest release can be found [here](https://github.com/subspace/subspace/pkgs/container/node))
> - chain (for example `gemini-2a`)
> - node name (in order to find your node on [Subspace Telemetry](https://telemetry.subspace.network/))

Pull fresh images and start containers:
```bash
docker-compose pull
docker-compose up -d
```
