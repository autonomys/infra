# DNS and uses (subspace.network)

Domain and Sub Domains compilation. Just to have a clear understanding of what we are exposing to the public in terms of content, product and development.

## Global DNS records

- subspace.network, web site, https://subspace.network
- status.subspace.network, public web site status, https://status.subspace.network

## Aries Testnet DNS records

- testnet-relayer https://testnet-relayer.subspace.network , proxy to CDN front end worker.
- test-rpc https://test-rpc.subspace.network , used by relayer front end and polkadot js apps

- aries-dev-relayer https://aries-dev-relayer.subspace.network , proxy to CDN front end worker.
- aries-dev-rpc.subspace.network, Public RPC node for development.
- aries-dev-bootnode.subspace.network, Bootnode for development.

- aries-test-relayer https://aries-test-relayer.subspace.network , proxy to CDN front end worker.
- aries-test-rpc.subspace.network, Public RPC node for testing.
- aries-test-bootnode.subspace.network, Bootnode for testing.

TODO. Discuss test and **test testnet** prefix as **aries** the current testnet name.

# CDN and workers projects

Created as a CNAME on cloudflare DNS, the workers will use this subdomain as path to handle requests and serve you app.

- aries-dev-relayer https://aries-dev-relayer.subspace.network

- aries-test-relayer https://aries-test-relayer.subspace.network
