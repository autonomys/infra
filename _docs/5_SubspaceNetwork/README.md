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
sudo apt install -y docker-ce docker-compose
```

### Nginx setup.

To expose the public RPC node over a secure WebSocket connection.

```bash
apt-get install -y nginx
```

### Certbot setup.

To generate an SSL certificate for the public RPC node.

```bash
snap install core
snap refresh core
apt-get remove certbot
snap install --classic certbot
ln -s /snap/bin/certbot /usr/bin/certbot
```

Following [certbot instructions](https://certbot.eff.org/lets-encrypt/ubuntufocal-nginx). We need a **subdomain (RPC_PUBLIC_NAME)** mapped to the Droplet **IP_ADDRESS** and a running **nginx** with an **open port 80**.

```bash
certbot certonly --nginx
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
service nginx restart
```

### Start the network.

In order to start the network you can create a simple setup with Docker Compose:
```bash
mkdir testnet
cd testnet
touch docker-compose.yml
```

Sample [docker-compose.yml](docker-compose.yml) can be used as a reference with following tweaks required:
* `/path/to/*` in all cases needs to be replaced with real paths owned by `nobody:nogroup`
* `GENERATED_BOOTSTRAP_NODE_ID_HERE` and `GENERATED_NODE_KEY_HERE` should be replaced with actual values.
  First time can be generated with following command (please retain values across testnets that are supposed to be
  identical):
  ```bash
  docker run --rm -it subspacelabs/subspace-node key generate-node-key
  ```

Now pull fresh images and spin up the network:
```bash
docker-compose pull
docker-compose up -d
```

Typical commands like `docker-compose restart`, `docker-compose logs --tail=100 -f` can be used to manage this setup,
see [Docker Compose docs](https://docs.docker.com/compose/reference/) for details.

Depending on setup you might want to use `:dev` tag of the image instead of `:latest` (implied if not specified).

### Stop containers and remove.

For **development** and **testing** purposes, you might want to reset the network to its initial state:
```bash
# Shut everything down
docker-compose down
# Clean directories
rm -rf /path/to/bootstrap-node/*
rm -rf /path/to/public-rpc-node/*
rm -rf /path/to/farmer-data/*
# Pull fresh images
docker-compose pull
# Start everything back up
docker-compose up -d
```

### TODO: Runtime Upgrade.

- In case of chain version spec upgrade, _add instructions to upgrade the chain version_.
