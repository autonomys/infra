# Block archives

## Create chain archive
TODO: add section

## Update archives
In order to keep existing archives up-to-date you can create a simple setup with Docker Compose:
```bash
mkdir update-archives
cd update-archives
touch docker-compose.yml
```

Sample [docker-compose.yml](docker-compose.yml) can be used as a reference.

Pull fresh image and start containers:
```bash
docker-compose pull
ONFINALITY_API_KEY="" docker-compose up -d
```
