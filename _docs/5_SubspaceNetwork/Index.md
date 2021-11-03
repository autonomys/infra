# Subspace Network environment.

A network is a collection of nodes and apps.
You can launch it following the next steps.

The current available Subspace Network version follow the Aries milestone.

A list of network minimal resources.

- Cloudflare resources.

  - _Network DNS_. (Optional for development or non public environments)
  - _Network CDN_. (If you need to deploy an app on a CDN, like the relayer front end)

- Subspace Apps.

  - Subspace Relayer Frontend
  - _Polkadot Apps._

- DigitalOcean resources.

  - Project / environment.

    - aries-**ENV**

  - Single Droplet.

    - Subspace Bootnode.
    - Subspace Public RPC.
    - Subspace Farmer.
    - Subspace Relayer Backend.

  - Volumes.

    - Parachains data from genesis block.

## Droplet apps.

**This do not cover CI/CD, we are asuming that you have a CI/CD system in place and at this point target network releases are already available trougth our Docker Hub repository.**

To start, we must declare the full workflow of launching a network and its apps.
This way can have a clear understanding for all team members or users that needs to run a network, for local, dev, test, staging, production we need to have a consistent workflow to ensure the network will run as expected, with the correct versions, dependencies, and resources.

After the network is deployed following terraform instructions, we can install the apps.

### Docker.

```
sudo apt-get update
sudo apt install apt-transport-https ca-certificates curl software-properties-common
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu focal stable"
apt-cache policy docker-ce
sudo apt install -y docker-ce
```

### Nginx to expose public rpc.

```
sudo apt-get install -y nginx
```

### Certbot for secure web socket certificates.

- Update snap, install certbot

```
sudo snap install core
sudo snap refresh core
sudo apt-get remove certbot
snap install --classic certbot
sudo ln -s /snap/bin/certbot /usr/bin/certbot
```

- Generate certificates only.
  **!! Need the domain RPC_PUBLIC_NAME created in cloudflare with target the droplet IP_ADDRESS and nginx serving over 80 port !!**

Follow instructions, cerbot will ask for some information, add your email to renewal notifications and set the domain to generate certificates.

```
sudo certbot certonly --nginx

# Success operation must log.
# Successfully received certificate.
# Certificate is saved at: /etc/letsencrypt/live/RPC_PUBLIC_NAME.network/fullchain.pem
# Key is saved at:         /etc/letsencrypt/live/RPC_PUBLIC_NAME.subspace.network/privkey.pem
```

- Create a config file for nginx and set the key directories.

```
sudo nano /etc/nginx/conf.d/RPC_PUBLIC_NAME.conf
```

- Replace IP_ADDRESS and RPC_PUBLIC_NAME with the correct values and save in the **/etc/nginx/conf.d/RPC_PUBLIC_NAME.conf** file.

```
server {

        server_name IP_ADDRESS;

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

        ssl_certificate /etc/letsencrypt/live/RPC_PUBLIC_NAME/fullchain.pem;
        ssl_certificate_key /etc/letsencrypt/live/RPC_PUBLIC_NAME/privkey.pem;

        ssl_session_cache shared:cache_nginx_SSL:1m;
        ssl_session_timeout 1440m;

        ssl_protocols TLSv1 TLSv1.1 TLSv1.2;
        ssl_prefer_server_ciphers on;

        ssl_ciphers "ECDHE-ECDSA-CHACHA20-POLY1305:ECDHE-RSA-CHACHA20-POLY1305:ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256:ECDHE-ECDSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-GCM-SHA384:DHE-RSA-AES128-GCM-SHA256:DHE-RSA-AES256-GCM-SHA384:ECDHE-ECDSA-AES128-SHA256:ECDHE-RSA-AES128-SHA256:ECDHE-ECDSA-AES128-SHA:ECDHE-RSA-AES256-SHA384:ECDHE-RSA-AES128-SHA:ECDHE-ECDSA-AES256-SHA384:ECDHE-ECDSA-AES256-SHA:ECDHE-RSA-AES256-SHA:DHE-RSA-AES128-SHA256:DHE-RSA-AES128-SHA:DHE-RSA-AES256-SHA256:DHE-RSA-AES256-SHA:ECDHE-ECDSA-DES-CBC3-SHA:ECDHE-RSA-DES-CBC3-SHA:EDH-RSA-DES-CBC3-SHA:AES128-GCM-SHA256:AES256-GCM-SHA384:AES128-SHA256:AES256-SHA256:AES128-SHA:AES256-SHA:DES-CBC3-SHA:!DSS";

        ssl_dhparam /etc/letsencrypt/ssl-dhparams.pem;

}

```

- Finally, restart the nginx service.

```
sudo service nginx restart
```

### Node 16 for relayer backend. (On stable version this must be a docker image)

```
mkdir /home/relayer-backend && cd /home/relayer-backend
curl -sL https://deb.nodesource.com/setup_16.x -o nodesource_setup.sh
sudo bash nodesource_setup.sh
sudo apt-get install -y nodejs
sudo apt-get install -y build-essential
```

#### PM2 global install.

```
npm i -g pm2
```

### Network images.

- All pre requisites are installed, we can start the network. Get the latest version from our Docker Hub repository.

```
docker pull subspacelabs/subspace-node
docker pull subspacelabs/subspace-farmer
```

#### Start subspace-node (bootnode)

- Create network, volume, start subspace-node.

```
docker network create subspace
docker volume create subspace-node

docker run -d --init \
    --net subspace \
    --name subspace-node \
    --mount source=subspace-node,target=/var/subspace \
    --publish 0.0.0.0:30333:30333 \
    --restart on-failure \
    subspacelabs/subspace-node \
        --chain testnet \
        --validator \
        --base-path /var/subspace \
        --telemetry-url "wss://telemetry.polkadot.io/submit/ 1" \
        --node-key 0000000000000000000000000000000000000000000000000000000000000001
```

- Check if subspace-node is running.

```
    docker logs subspace-node  -f
```

#### Start subspace-node-public. (public-rpc)

- Create volume, subspace-node-public, check and replace BOOTNODE_IP_OR_DNS.

```
docker volume create subspace-node-public

docker run -d --init \
    --net subspace \
    --name subspace-node-public \
    --mount source=subspace-node-public,target=/var/subspace \
    --publish 0.0.0.0:9944:9944 \
    --publish 0.0.0.0:9933:9933 \
    --restart on-failure \
    subspacelabs/subspace-node \
        --chain testnet \
        --validator \
        --rpc-cors all \
        --rpc-methods Unsafe \
        --base-path /var/subspace \
        --ws-external \
        --bootnodes /ip4/165.232.145.171/tcp/30333/p2p/12D3KooWEyoppNCUx8Yx66oV9fJnriXwCcXwDDUA2kj6vnc6iDEp \
        --telemetry-url "wss://telemetry.polkadot.io/submit/ 1"
```

- Check if subspace-node-public is running.

```
    docker logs subspace-node-public  -f
```

#### Start subspace-farmer

- Create volume, run subspace-farmer.

```
docker volume create subspace-farmer

docker run -d --init \
    --net subspace \
    --name subspace-farmer \
    --mount source=subspace-farmer,target=/var/subspace \
    --restart on-failure \
    subspacelabs/subspace-farmer \
        farm \
        --ws-server ws://subspace-node-public:9944
```

- Check if subspace-farmer is running.

```
    docker logs subspace-farmer  -f
```

- Check if network is producing blocks.

```
    docker logs subspace-node-public  -f
```

### Relayer backend.

- Get the latest relayer version and build it.

```
cd /home/relayer-backend
git clone https://github.com/subspace/subspace-relayer.git && cd subspace-relayer/backend
npm i
npm run build
```

#### Start relayer backend in "local mode"

- Copy the last blocks to your mounted **VOLUME_NAME**.
- This data is available over **165.232.157.230**.
- Need to generate keys on the current droplet and add the public key to **165.232.157.230**.
- Then copy the data. Replace **VOLUME_NAME**.

```
scp -r root@165.232.157.230:/mnt/volume_sfo3_03/Kusama-archives /mnt/VOLUME_NAME
cd /home/relayer-backend/subspace-relayer/backend/src/config
sudo nano archives.json

```

- Paste the following config to get parachain archives. Replace **VOLUME_NAME**.

```
[
  {
    "url": "wss://kusama-rpc.polkadot.io",
    "path": "/mnt/VOLUME_NAME/Kusama-archives/kusama-archive-2021-oct-23/"
  }
]

```

- Run the relayer backend to import the blocks.

```
pm2 start /home/relayer-backend/subspace-relayer/backend/dist/index.js --name relayer-backend
pm2 logs relayer-backend
```

#### Start relayer backend in "live mode"

- After the "local mode" import is completed.

```
pm2 stop relayer-backend
pm2 start /home/relayer-backend/subspace-relayer/backend/dist/index.js --name relayer-backend
pm2 logs relayer-backend
```

### Datadog for remote logging.

- This will start datadog with auto discovery sending docker logs to datadog. Replace DD_API_KEY.

```

    docker run -d --name datadog-agent \
    -e DD_API_KEY=9999999999999999999999999999999 \
    -e DD_LOGS_ENABLED=true \
    -e DD_LOGS_CONFIG_CONTAINER_COLLECT_ALL=true \
    -e DD_CONTAINER_EXCLUDE_LOGS="name:datadog-agent" \
    -v /var/run/docker.sock:/var/run/docker.sock:ro \
    -v /proc/:/host/proc/:ro \
    -v /opt/datadog-agent/run:/opt/datadog-agent/run:rw \
    -v /sys/fs/cgroup/:/host/sys/fs/cgroup:ro \
    datadog/agent:latest

```

- Check log status, https://app.datadoghq.com/logs

### TODO: Full Network Reset.

- For **development** and **testing**, you can reset the network to its initial state.

### TODO: Runtime Upgrade.

- In case of chain version spec upgrade, _add instructions to upgrade the chain version_.

```

```
