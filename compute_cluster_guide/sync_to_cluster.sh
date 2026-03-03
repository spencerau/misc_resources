#!/bin/bash

# Simple script to sync your project to a compute cluster and run Ollama
# This demonstrates a typical workflow for cluster deployment

# Load configuration from .env file if it exists
if [ -f ".env" ]; then
  echo "Loading configuration from .env file..."
  set -a  # automatically export all variables
  source .env
  set +a  # stop automatically exporting
fi

# Default values (override with .env file or environment variables)
CLUSTER_HOST=${CLUSTER_HOST}
CLUSTER_USER=${CLUSTER_USER}
REMOTE_PROJECT_DIR=${REMOTE_PROJECT_DIR}
OLLAMA_PORT=${OLLAMA_PORT}

echo "=== Compute Cluster Deployment Guide ==="
echo "Syncing project to cluster and setting up Ollama..."
echo ""

# Create a simple project archive (excluding common unnecessary files)
echo "Creating project archive..."
tar -czf /tmp/project-sync.tar.gz \
    --exclude='.git' \
    --exclude='__pycache__' \
    --exclude='*.pyc' \
    --exclude='.DS_Store' \
    --exclude='node_modules' \
    --exclude='*.log' \
    . 2>/dev/null || true

echo "Transferring files to cluster..."
scp /tmp/project-sync.tar.gz "${CLUSTER_USER}@${CLUSTER_HOST}:/tmp/"

echo "Setting up project on cluster..."
ssh "${CLUSTER_USER}@${CLUSTER_HOST}" "
    # Create project directory if it doesn't exist
    mkdir -p ${REMOTE_PROJECT_DIR}
    cd ${REMOTE_PROJECT_DIR}
    
    # Extract project files
    tar -xzf /tmp/project-sync.tar.gz 2>/dev/null || true
    rm /tmp/project-sync.tar.gz
    
    # Make scripts executable
    chmod +x *.sh 2>/dev/null || true
    
    echo 'Project files synced successfully!'
"

# Clean up local temp file
rm -f /tmp/project-sync.tar.gz

echo "✅ Files synced to cluster!"
echo ""
echo "=== Next Steps ==="
echo "1. Connect to your cluster:"
echo "   ssh ${CLUSTER_USER}@${CLUSTER_HOST}"
echo ""
echo "2. Navigate to your project:"
echo "   cd ${REMOTE_PROJECT_DIR}"
echo ""
echo "3. Set up Ollama port (optional, defaults to 11434):"
echo "   export OLLAMA_PORT=${OLLAMA_PORT}"
echo ""
echo "4. Start Ollama container:"
echo "   ./run_cluster.sh"
echo ""
echo "5. Create SSH tunnel to access from your local machine:"
echo "   ssh -L ${OLLAMA_PORT}:localhost:${OLLAMA_PORT} ${CLUSTER_USER}@${CLUSTER_HOST}"
echo ""
echo "6. Test Ollama API from your local machine:"
echo "   curl http://localhost:${OLLAMA_PORT}/api/tags"
echo ""
echo "=== Useful Commands (run on cluster) ==="
echo "# Check container status:"
echo "   docker ps"
echo ""
echo "# View Ollama logs:"
echo "   docker logs ollama-container"
echo ""
echo "# Stop Ollama:"
echo "   docker stop ollama-container"
echo ""
echo "# Pull a model:"
echo "   curl -X POST http://localhost:${OLLAMA_PORT}/api/pull -d '{\"name\": \"llama3.2\"}'"
