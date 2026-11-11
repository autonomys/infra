#!/usr/bin/env python3
"""Refuses a Compose model that would publish a port beyond loopback.

Docker-published ports bypass the firewall, so a role's deploy pipes
`docker compose config --format json` through this before starting anything.
A port may be published on loopback, on one of PRIVATE_ADDRESSES (such as the
host's mesh address), or anywhere if it is a TCP port in PUBLIC_TCP_PORTS. Both
are space-separated and may be empty.
"""

import json
import os
import sys

public_tcp_ports = set(os.environ.get("PUBLIC_TCP_PORTS", "").split())
private_addresses = set(os.environ.get("PRIVATE_ADDRESSES", "").split())

bad = []
for name, service in json.load(sys.stdin)["services"].items():
    for port in service.get("ports", []):
        host_ip = port.get("host_ip") or "0.0.0.0"
        published = str(port.get("published"))
        protocol = port.get("protocol", "tcp")
        if host_ip in ("127.0.0.1", "::1") or host_ip in private_addresses:
            continue
        if published in public_tcp_ports and protocol == "tcp":
            continue
        bad.append("%s: %s:%s/%s" % (name, host_ip, published, protocol))

if bad:
    print("Refusing to deploy, these ports would be published beyond loopback:", *bad, sep="\n  ", file=sys.stderr)
    sys.exit(1)
