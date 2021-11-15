# Subspace Network environment.

A network is a collection of nodes and apps. You can launch it following the next steps.

- Cloudflare resources.

  - _Network DNS_. (Optional for development)
  - _Network CDN_. (To deploy an app using Cloudflare workers, like the relayer front end)

- DigitalOcean resources.

  - Wrap all **ENV** resources over a DigitalOcean project.

    - aries-**ENV**

  - Use a single Droplet to launch a new **ENV**.

    - Subspace Bootnode.
    - Subspace Public RPC.
    - Subspace Farmer.
    - Subspace Relayer Backend.

  - Volume attached to a single Droplet **ENV**.
    - Will contain relayer archive and farmer plot.

## System requirements.

The following instructions contain the minimal requirements to run Docker images for a Subspace Network.

### Docker setup.

To run our docker images and Datadog agent integration.

```bash
sudo apt-get update
sudo apt install -y apt-transport-https ca-certificates curl software-properties-common
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu focal stable"
apt-cache policy docker-ce
sudo apt install -y docker-ce
```

### Nginx setup.

To expose the public RPC node over a secure WebSocket connection.

```bash
sudo apt-get install -y nginx
```

### Certbot setup.

To generate an SSL certificate for the public RPC node.

```bash
sudo snap install core
sudo snap refresh core
sudo apt-get remove certbot
snap install --classic certbot
sudo ln -s /snap/bin/certbot /usr/bin/certbot
```

Following [certbot instructions](https://certbot.eff.org/lets-encrypt/ubuntufocal-nginx). We need a **subdomain (RPC_PUBLIC_NAME)** mapped to the Droplet **IP_ADDRESS** and a running **nginx** with an **open port 80**.

```bash
sudo certbot certonly --nginx
```

Success operation output.

```
Successfully received certificate.
Certificate is saved at: /etc/letsencrypt/live/RPC_PUBLIC_NAME.network/fullchain.pem
Key is saved at:         /etc/letsencrypt/live/RPC_PUBLIC_NAME.subspace.network/privkey.pem
```

Finally, create a config file for nginx and set the key directories.

```bash
sudo nano /etc/nginx/conf.d/iac.trojan.finance.conf
```

Replace **IP_ADDRESS** and **RPC_PUBLIC_NAME** with the correct values and save in the **/etc/nginx/conf.d/RPC_PUBLIC_NAME.conf** file.

```conf
server {

        server_name 143.198.142.170;

        root /var/www/html;
        index index.html;

        location / {
          try_files $uri $uri/ =404;

          proxy_buffering off;
          proxy_pass http://localhost:9944;
          proxy_set_header X-Real-IP $remote_addr;
          proxy_set_header Host $host;
          proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;

          proxy_http_version 1.1;
          proxy_set_header Upgrade $http_upgrade;
          proxy_set_header Connection "upgrade";
        }

        listen [::]:443 ssl ipv6only=on;
        listen 443 ssl;

        ssl_certificate /etc/letsencrypt/live/iac.trojan.finance/fullchain.pem;
        ssl_certificate_key /etc/letsencrypt/live/iac.trojan.finance/privkey.pem;

        ssl_session_cache shared:cache_nginx_SSL:1m;
        ssl_session_timeout 1440m;

        ssl_protocols TLSv1 TLSv1.1 TLSv1.2;
        ssl_prefer_server_ciphers on;

        ssl_ciphers "ECDHE-ECDSA-CHACHA20-POLY1305:ECDHE-RSA-CHACHA20-POLY1305:ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256:ECDHE-ECDSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-GCM-SHA384:DHE-RSA-AES128-GCM-SHA256:DHE-RSA-AES256-GCM-SHA384:ECDHE-ECDSA-AES128-SHA256:ECDHE-RSA-AES128-SHA256:ECDHE-ECDSA-AES128-SHA:ECDHE-RSA-AES256-SHA384:ECDHE-RSA-AES128-SHA:ECDHE-ECDSA-AES256-SHA384:ECDHE-ECDSA-AES256-SHA:ECDHE-RSA-AES256-SHA:DHE-RSA-AES128-SHA256:DHE-RSA-AES128-SHA:DHE-RSA-AES256-SHA256:DHE-RSA-AES256-SHA:ECDHE-ECDSA-DES-CBC3-SHA:ECDHE-RSA-DES-CBC3-SHA:EDH-RSA-DES-CBC3-SHA:AES128-GCM-SHA256:AES256-GCM-SHA384:AES128-SHA256:AES256-SHA256:AES128-SHA:AES256-SHA:DES-CBC3-SHA:!DSS";

        ssl_dhparam /etc/letsencrypt/ssl-dhparams.pem;

}

```

Restart the nginx service to load the config file.

```bash
sudo service nginx restart
```

### Start the network.

1. Run docker containers.

#### Get Network images.

Pull from Docker hub.

- Latest images:

```
docker pull subspacelabs/subspace-node:latest
docker pull subspacelabs/subspace-farmer:latest
```

- Development images:

```
docker pull subspacelabs/subspace-node:dev
docker pull subspacelabs/subspace-farmer:dev
```

#### Create network.

All network containers need a shared network.

```
docker network create subspace
```

#### Set _subspacelabs_ images tag.

Docker will always use **latest** images if it not specified.

In the **next steps**, we will run containers from **subspacelabs/image:tag** with `docker run` command, for each container be aware of the tag used.

- Check the image line and replace **$DOCKER_TAG_ENV** for your needs (dev or latest):

  - Nodes: `subspacelabs/subspace-node$DOCKER_TAG_ENV` to `subspacelabs/subspace-node:dev`
  - Farmer: `subspacelabs/subspace-farmer$DOCKER_TAG_ENV` to `subspacelabs/subspace-farmer:dev`

- Or you can export **DOCKER_TAG_ENV** as you need. This also help to run ensure consistency.

```bash
    export DOCKER_TAG_ENV=":dev"
    ## OR
    export DOCKER_TAG_ENV=":latest"
```

- If you dont do anything, the following steps will run **latest** images.

#### Start bootnode.

1. Create bootnode volume.
2. Start bootnode.

```bash
docker volume create subspace-node

docker run -d --init \
    --net subspace \
    --name subspace-node \
    --mount source=subspace-node,target=/var/subspace \
    --publish 0.0.0.0:30333:30333 \
    --restart on-failure \
    subspacelabs/subspace-node$DOCKER_TAG_ENV \
        --chain testnet \
        --validator \
        --base-path /var/subspace \
        --telemetry-url "wss://telemetry.polkadot.io/submit/ 1" \
        --node-key 0000000000000000000000000000000000000000000000000000000000000001
```

3. Check the logs.

```
    docker logs subspace-node -f
```

#### Start public rpc node.

1. Create node volume.
2. Configure **rpc node** to connect with **bootnode**.

   - Replace **$BOOTNODE_IP** with the bootnode address.

     `--bootnodes /ip4/$BOOTNODE_IP/tcp/30333/p2p/12D3KooWEyoppNCUx8Yx66oV9fJnriXwCcXwDDUA2kj6vnc6iDEp \`

   - Or you can use this command to **inspect** the running bootnode (**subspace-node**) container and export the **BOOTNODE_IP**.

   ```bash
   export BOOTNODE_IP=$(docker inspect -f '{{range.NetworkSettings.Networks}}{{.IPAddress}}{{end}}' subspace-node)
   ```

3. Start rpc node.

```bash
docker volume create subspace-node-public

docker run -d --init \
    --net subspace \
    --name subspace-node-public \
    --mount source=subspace-node-public,target=/var/subspace \
    --publish 0.0.0.0:9944:9944 \
    --publish 0.0.0.0:9933:9933 \
    --restart on-failure \
    subspacelabs/subspace-node$DOCKER_TAG_ENV \
        --chain testnet \
        --validator \
        --rpc-cors all \
        --rpc-methods Unsafe \
        --base-path /var/subspace \
        --ws-external \
        --bootnodes /ip4/$BOOTNODE_IP/tcp/30333/p2p/12D3KooWEyoppNCUx8Yx66oV9fJnriXwCcXwDDUA2kj6vnc6iDEp \
        --telemetry-url "wss://telemetry.polkadot.io/submit/ 1"
```

3. Check the logs.

```
docker logs subspace-node-public  -f
```

#### Start farmer.

1. Create farmer volume.
2. Start farmer.

```bash
docker volume create subspace-farmer

docker run -d --init \
    --net subspace \
    --name subspace-farmer \
    --mount source=subspace-farmer,target=/var/subspace \
    --restart on-failure \
    subspacelabs/subspace-farmer$DOCKER_TAG_ENV \
        farm \
        --ws-server ws://subspace-node-public:9944
```

3. Check the logs.

```
docker logs subspace-farmer  -f
```

#### Validate the network.

Check if network is producing blocks.

```
    docker logs subspace-node-public  -f
```

### Stop containers and remove.

For **development** and **testing** purposes, you can reset the network to its initial state, this will **stop** and **delete** all docker **containers** and **volumes** with a name starting with `subspace-`.

```bash
    docker stop $(docker ps --filter name=subspace- -aq)
    docker container rm $(docker ps --filter name=subspace- -aq)
    docker volume rm $(docker volume ls --filter name=subspace- -q)
```

### Run from scripts. (For dev and testing)

You can also run the following bash scripts to start the network, will be useful for **development** and **testing** purposes.

- [run-subspace-containers.sh](./run-subspace-containers.sh)

  1. REMOVE and RUN dev containers.
  2. REMOVE and RUN latest containers.
  3. STOP RUNNING NETWORK 
  4. START EXISTING NETWORK 
  5. PURGE (NETWORK STATE WILL BE LOST)
  6. Subspace-node-public logs -f
  7. RUN Datadog agent container.
  8. Docker ps - show running containers status.

### TODO: Runtime Upgrade.

- In case of chain version spec upgrade, _add instructions to upgrade the chain version_.
