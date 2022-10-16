# Subsquid archive

Subspace Network maintains [Subsquid Archive](https://docs.subsquid.io/archives/) in order to store raw chain data in a normalized way and expose it using GraphQL endpoint

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
