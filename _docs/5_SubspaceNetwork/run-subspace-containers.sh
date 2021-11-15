#!/bin/sh

start() {
    echo "||start-network----- STARTING CONTAINERS"
    docker start subspace-node
    docker start subspace-node-public
    docker start subspace-farmer
    echo "||start-network----- DONE"
}

stop() {
    echo "||stop-network----- STOPPING CONTAINERS..."
    docker stop $(docker ps --filter name=subspace- -aq)
    echo "||stop-network----- DONE"
}

wipe() {
    echo "||wipe-network----- STOP CONTAINERS"
    stop
    echo "||wipe-network----- REMOVING CONTAINERS..."
    docker container rm $(docker ps --filter name=subspace- -aq)
    echo "||wipe-network----- CONTAINERS REMOVED"
    echo "|| ..."
    echo "||wipe-network----- REMOVING VOLUMES..."
    docker volume rm $(docker volume ls --filter name=subspace- -q)
    echo "||wipe-network----- VOLUMES REMOVED"
}

public-logs() {
    docker logs subspace-node --tail 1000 -f
}

create-network() {
    echo "||create-network----- CREATING..."
    docker network remove subspace
    docker network create subspace
    echo "||create-network----- DONE"

}

create-volumes() {
    echo "||create-volumes----- CREATING..."
    docker volume create subspace-node
    docker volume create subspace-node-public
    docker volume create subspace-farmer
    echo "||create-volumes----- DONE"
}

pull-run-latest() {
    export DOCKER_TAG_ENV=":latest"
    run-all-nodes
}

pull-run-dev() {
    export DOCKER_TAG_ENV=":dev"
    run-all-nodes
}

run-all-nodes() {
    wipe
    create-network
    create-volumes

    echo "||run-network----- DOCKER_TAG_ENV=$DOCKER_TAG_ENV"
    echo "||run-network----- RUN BOOTNODE ..."
    docker run -d --init \
        --net subspace \
        --name subspace-node \
        --mount source=subspace-node,target=/var/subspace \
        --publish 0.0.0.0:30333:30333 \
        --restart unless-stopped \
        subspacelabs/subspace-node$DOCKER_TAG_ENV \
        --chain testnet \
        --validator \
        --base-path /var/subspace \
        --telemetry-url "wss://telemetry.polkadot.io/submit/ 1" \
        --node-key 0000000000000000000000000000000000000000000000000000000000000001

    export BOOTNODE_IP=$(docker inspect -f '{{range.NetworkSettings.Networks}}{{.IPAddress}}{{end}}' subspace-node)

    echo "||run-network----- RUN RPC NODE..."
    docker run -d --init \
        --net subspace \
        --name subspace-node-public \
        --mount source=subspace-node-public,target=/var/subspace \
        --publish 0.0.0.0:9944:9944 \
        --publish 0.0.0.0:9933:9933 \
        --restart unless-stopped \
        subspacelabs/subspace-node$DOCKER_TAG_ENV \
        --chain testnet \
        --validator \
        --rpc-cors all \
        --rpc-methods Unsafe \
        --base-path /var/subspace \
        --ws-external \
        --telemetry-url "wss://telemetry.polkadot.io/submit/ 1" \
        --bootnodes /ip4/$BOOTNODE_IP/tcp/30333/p2p/12D3KooWEyoppNCUx8Yx66oV9fJnriXwCcXwDDUA2kj6vnc6iDEp

    echo "||run-network-----RUN FARMER..."
    docker run -d --init \
        --net subspace \
        --name subspace-farmer \
        --mount source=subspace-farmer,target=/var/subspace \
        --restart unless-stopped \
        subspacelabs/subspace-farmer$DOCKER_TAG_ENV \
        farm \
        --ws-server ws://subspace-node-public:9944
    echo "||run-network-----DONE"

}

##
# Color  Variables
##

##
# Color  Variables
##

green='\e[32m'
blue='\e[34m'
clear='\e[0m'
red='\e[31m'

##
# Color Functions
##

ColorGreen() {
    echo -ne $green$1$clear
}
ColorBlue() {
    echo -ne $blue$1$clear
}
ColorRed() {
    echo -ne $red$1$clear
}

menu() {
    echo -ne "
    -----------------------------------------------------
    -----------------=[Subspace Aries]=------------------
    -----------------------------------------------------
    | Option 1 and 2 will REMOVE docker resources named |
    |          subspace-* for dev or latest container   |
    -----------------------------------------------------
    -----------------------------------------------------
    $(ColorGreen '1)') REMOVE and RUN dev containers.
    $(ColorGreen '2)') REMOVE and RUN latest containers.
    $(ColorBlue '3)') STOP  RUNNING NETWORK - TODO: broken network on restart
    $(ColorBlue '4)') START EXISTING NETWORK - TODO: broken network on restart
    $(ColorRed '5)') PURGE (NETWORK STATE WILL BE LOST)
    $(ColorBlue '6)') Subspace-node-public logs -f
    $(ColorBlue '7)') RUN Datadog agent container.
    $(ColorBlue '8)') Docker ps - show running containers status.
    $(ColorBlue 'Choose an option:') $clear"

    read a
    case $a in
    1)
        pull-run-dev
        menu
        ;;
    2)
        pull-run-latest
        menu
        ;;
    3)
        echo "----------------------------------------------------------------------"
        echo "WIP - some error on stop and start container node cant find archiver"
        echo "Incorrect parameters for archiver: NoBlocksInvalidInitialState', /code/crates/sc-consensus-subspace/src/archiver.rs:131"
        echo "----------------------------------------------------------------------"
        #stop
        menu
        ;;
    4)
        echo "----------------------------------------------------------------------"
        echo "WIP - some error on stop and start container node cant find archiver"
        echo "Incorrect parameters for archiver: NoBlocksInvalidInitialState', /code/crates/sc-consensus-subspace/src/archiver.rs:131"
        echo "----------------------------------------------------------------------"
        #start
        menu
        ;;
    5)
        wipe
        menu
        ;;
    6)
        public-logs
        menu
        ;;

    7)
        echo -n "Enter Datadog API_KEY: "
        read API_KEY
        case $API_KEY in
        "")
            printf "\n"
            echo "INVALID KEY"
            menu
            ;;
        *)
            printf "\n"
            echo "----DD_API_KEY=$API_KEY"

            docker run -d --name datadog-agent \
                -e DD_API_KEY=$API_KEY \
                -e DD_LOGS_ENABLED=true \
                -e DD_LOGS_CONFIG_CONTAINER_COLLECT_ALL=true \
                -e DD_CONTAINER_EXCLUDE_LOGS="name:datadog-agent" \
                -v /var/run/docker.sock:/var/run/docker.sock:ro \
                -v /proc/:/host/proc/:ro \
                -v /opt/datadog-agent/run:/opt/datadog-agent/run:rw \
                -v /sys/fs/cgroup/:/host/sys/fs/cgroup:ro \
                datadog/agent:latest
            ;;
        esac
        menu
        ;;
    8)
        docker ps
        menu
        ;;
    0) exit 0 ;;
    *)
        echo -e "Not a Valid Option, Try Again..."
        menu
        ;;
    esac

}

menu
