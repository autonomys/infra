# Docker.

## Subspace.

Latest Subspace images are available in [Subspace Docker Hub](https://hub.docker.com/u/subspacelabs) .

- https://hub.docker.com/r/subspacelabs/subspace-farmer
- https://hub.docker.com/r/subspacelabs/subspace-node

## Relayer backend

### Download full chain from genesis.

Follow the instructions to run the download tool:

- https://github.com/subspace/subspace-relayer/blob/main/backend/relayer-download.md

### "local mode"

Follow the instructions to run over a docker container:

- https://github.com/subspace/subspace-relayer/blob/main/backend/relayer-archive.md

### "live mode"

Follow the instructions to run over a docker container:

- https://github.com/subspace/subspace-relayer/blob/main/backend/relayer-live.md

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
