# Docker.

## Subspace.

Latest Subspace images are available in [Subspace Docker Hub](https://hub.docker.com/u/subspacelabs) .

- https://hub.docker.com/r/subspacelabs/subspace-farmer
- https://hub.docker.com/r/subspacelabs/subspace-node

- TODO: relayer backend.

## Datadog.

This simple configuration will allow us to connect to the datadog agent from the running containers and send logs to the datadog service.

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
