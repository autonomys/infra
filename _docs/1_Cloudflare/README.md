# DNS and uses (subspace.network)

Domain and Sub Domains compilation.
To clarify what we are exposing to the public in terms of content, product, and development.

## Global DNS records

- subspace.network, web site, https://subspace.network
- status.subspace.network, public web site status, https://status.subspace.network

## Aries DNS records (Current)

- testnet-relayer https://testnet-relayer.subspace.network | Proxy to CDN front end worker.
- test-rpc https://test-rpc.subspace.network | Used by relayer front end and Polkadot js apps

## Aries DNS records.

DEV:

- aries-dev-rpc.subspace.network, Public RPC node for development.

TEST:

- aries-test-rpc.subspace.network, Public RPC node for testing.

# CDN and workers projects

Created as a CNAME on Cloudflare DNS, the workers will use this subdomain as the path to handle requests and serve the app.

DEV:

- aries-dev-relayer https://aries-dev-relayer.subspace.network

TEST:

- aries-test-relayer https://aries-test-relayer.subspace.network
