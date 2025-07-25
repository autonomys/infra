#!/bin/bash

# Config
AWS_USER=ubuntu
AWS_HOST=aws-ec2-host
CONTAINER_NAME="subspace-archival-node-1"
LOCAL_DEST_DIR="~/Downloads"  # or any path on your local machine

# Node configuration - MODIFY THESE AS NEEDED
NODE_TYPE="evm"        # Options: "evm" or "rpc"
NETWORK="mainnet"      # Options: "mainnet" or "taurus"

# Determine archive name based on node type and network
if [ "$NODE_TYPE" = "evm" ]; then
    ARCHIVE_NAME="snapshot-archive-${NETWORK}-domain.tar.zst"
elif [ "$NODE_TYPE" = "rpc" ]; then
    ARCHIVE_NAME="snapshot-archive-${NETWORK}-consensus.tar.zst"
else
    echo "Error: NODE_TYPE must be either 'evm' or 'rpc'"
    exit 1
fi

echo "📦 Starting backup for $NODE_TYPE node on $NETWORK network"
echo "📁 Archive will be named: $ARCHIVE_NAME"

# SSH and run the backup steps asynchronously
ssh "$AWS_USER@$AWS_HOST" "bash -s" <<EOF &
nohup bash -c '
    set -e
    NODE_TYPE="$NODE_TYPE"
    NETWORK="$NETWORK"
    ARCHIVE_NAME="$ARCHIVE_NAME"

    echo "[1/6] Copying from Docker container $CONTAINER_NAME..."
    mkdir -p \$HOME/snapshot
    sudo docker cp $CONTAINER_NAME:/var/subspace \$HOME/snapshot

    # Check if zstd is installed, if not install it
    if ! command -v zstd &> /dev/null; then
        echo "zstd could not be found, installing..."
        sudo apt-get update && sudo apt-get install -y zstd
    fi
    echo "zstd installed successfully."

    echo "[2/6] Removing node-specific directories..."
    if [ "$NODE_TYPE" = "evm" ]; then
        echo "EVM node detected - removing keystore and network folders..."
        rm -rf \$HOME/snapshot/subspace/keystore
        rm -rf \$HOME/snapshot/subspace/network
    elif [ "$NODE_TYPE" = "rpc" ]; then
        echo "RPC node detected - removing network folder..."
        rm -rf \$HOME/snapshot/subspace/network
    fi

    echo "[3/6] Compressing snapshot with zstd..."
    tar --use-compress-program=zstd -cf \$HOME/\$ARCHIVE_NAME -C \$HOME snapshot

    echo "[4/6] Archive created successfully at \$HOME/\$ARCHIVE_NAME"

    echo "[5/6] Cleaning up..."
    # Note: Archive is kept on server for manual download
    rm -rf \$HOME/snapshot

    echo "✅ Snapshot process completed for \$NODE_TYPE node on \$NETWORK network."
    echo "📁 Archive \$ARCHIVE_NAME is ready for download"
' > \$HOME/snapshot_log.txt 2>&1 &
EOF

echo "🚀 Backup process started remotely for $NODE_TYPE node on $NETWORK network."
echo "📋 Logs will be in ~/snapshot_log.txt on the AWS server."
echo "📁 Final archive: $ARCHIVE_NAME"
echo ""
echo "⏳ Waiting for backup to complete..."

# Wait for the background process to complete
wait

echo ""
echo "📥 Now downloading the archive..."
scp "$AWS_USER@$AWS_HOST:$ARCHIVE_NAME" "$LOCAL_DEST_DIR"

if [ $? -eq 0 ]; then
    echo "✅ Download completed successfully!"
    echo "🧹 Cleaning up archive from server..."
    ssh "$AWS_USER@$AWS_HOST" "rm -f $ARCHIVE_NAME"
    echo "✅ Server cleanup completed!"
else
    echo "❌ Download failed. Archive remains on server at: $ARCHIVE_NAME"
fi
