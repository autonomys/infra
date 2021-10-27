# Configure a public WSS node.

WIP, feel free to improve.

- Pre requisites.

- A domain name. (we use Cloudflare)
- A vm with a public ip. (we use DigitalOcean)

# Configure a public WSS node.

- Once droplet is launched, access as root user, update system.
  `sudo apt update`

- Create a new user.
  `adduser testnet-user-01`

- Add User to sudo group
  `usermod -aG sudo testnet-user-01`

- Login your new user.
  `su - testnet-user-01`

# Install nginx

`sudo apt install nginx.`

# Install certbot

Follow: https://certbot.eff.org/lets-encrypt/ubuntubionic-nginx.html **using your domain name**

`sudo apt install certbot python3-certbot-nginx.`

# Configure nginx

Edit nginx configuration. adding your server name and ssl certificates directories.

```
server {

        server_name SAMPLE-RPC-DOMAIN.COM;

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
        ssl_certificate /etc/letsencrypt/live/SAMPLE-RPC-DOMAIN.COM/fullchain.pem;
        ssl_certificate_key /etc/letsencrypt/live/SAMPLE-RPC-DOMAIN.COM/privkey.pem;

        ssl_session_cache shared:cache_nginx_SSL:1m;
        ssl_session_timeout 1440m;

        ssl_protocols TLSv1 TLSv1.1 TLSv1.2;
        ssl_prefer_server_ciphers on;

        ssl_ciphers "ECDHE-ECDSA-CHACHA20-POLY1305:ECDHE-RSA-CHACHA20-POLY1305:ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256:ECDHE-ECDSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-GCM-SHA384:DHE-RSA-AES128-GCM-SHA256:DHE-RSA-AES256-GCM-SHA384:ECDHE-ECDSA-AES128-SHA256:ECDHE-RSA-AES128-SHA256:ECDHE-ECDSA-AES128-SHA:ECDHE-RSA-AES256-SHA384:ECDHE-RSA-AES128-SHA:ECDHE-ECDSA-AES256-SHA384:ECDHE-ECDSA-AES256-SHA:ECDHE-RSA-AES256-SHA:DHE-RSA-AES128-SHA256:DHE-RSA-AES128-SHA:DHE-RSA-AES256-SHA256:DHE-RSA-AES256-SHA:ECDHE-ECDSA-DES-CBC3-SHA:ECDHE-RSA-DES-CBC3-SHA:EDH-RSA-DES-CBC3-SHA:AES128-GCM-SHA256:AES256-GCM-SHA384:AES128-SHA256:AES256-SHA256:AES128-SHA:AES256-SHA:DES-CBC3-SHA:!DSS";

        ssl_dhparam /etc/letsencrypt/ssl-dhparams.pem;

}
```

Restart nginx after setting this up: sudo service nginx restart.

# Install Docker

```
sudo apt install apt-transport-https ca-certificates curl software-properties-common
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add
sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu focal stable"
sudo apt update
sudo apt install docker-ce
```

```
sudo usermod -aG docker ${USER}
exit # to reload user
su - testnet-user-01
```

# Install Docker Compose

```
sudo curl -L "https://github.com/docker/compose/releases/download/1.29.2/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose
docker-compose --version # to check running command
```

## Pull images and create volumes

```
docker network create subspace
docker pull subspacelabs/subspace-node
docker pull subspacelabs/subspace-farmer
```

# Run subspace-node

```
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

# Run subspace-node-public

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
 --bootnodes /ip4/165.232.157.230/tcp/30333/p2p/12D3KooWEyoppNCUx8Yx66oV9fJnriXwCcXwDDUA2kj6vnc6iDEp \
 --telemetry-url "wss://telemetry.polkadot.io/submit/ 1"
```

# Run subspace-farmer

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
