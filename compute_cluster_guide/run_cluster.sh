#!/bin/bash

# Simple Ollama cluster deployment script
# This script demonstrates how to run Ollama on a compute cluster using Docker

# Load configuration from .env file if it exists
if [ -f ".env" ]; then
  echo "Loading configuration from .env file..."
  set -a  # automatically export all variables
  source .env
  set +a  # stop automatically exporting
fi

# Default values if not set in .env or environment
OLLAMA_PORT=${OLLAMA_PORT:-11434}
CONTAINER_NAME=${CONTAINER_NAME:-"ollama-container"}
GPU_CONFIG=${GPU_CONFIG:-"1"}
OLLAMA_MODELS_DIR=${OLLAMA_MODELS_DIR:-"$(pwd)/ollama_models"}
NVIDIA_VISIBLE_DEVICES=${NVIDIA_VISIBLE_DEVICES:-"all"}
NVIDIA_DRIVER_CAPABILITIES=${NVIDIA_DRIVER_CAPABILITIES:-"compute,utility"}

echo "Starting Ollama on port ${OLLAMA_PORT}..."

if curl -s "http://localhost:${OLLAMA_PORT}/api/tags" >/dev/null 2>&1; then
  echo "Ollama is already running and accessible on port ${OLLAMA_PORT}"
else
  echo "Ollama not accessible on port ${OLLAMA_PORT}, starting container..."
  
  if docker ps -a | grep -q "${CONTAINER_NAME}"; then
    echo "Stopping existing container..."
    docker stop "${CONTAINER_NAME}" 2>/dev/null || true
    docker rm "${CONTAINER_NAME}" 2>/dev/null || true
  fi
  
  echo "Starting Ollama container..."
  
  # Build GPU arguments based on configuration
  GPU_ARGS=""
  if [ -n "$GPU_CONFIG" ] && [ "$GPU_CONFIG" != "none" ]; then
    GPU_ARGS="--runtime=nvidia --gpus $GPU_CONFIG"
  fi
  
  # Build the docker run command
  docker run -d \
    --name "${CONTAINER_NAME}" \
    $GPU_ARGS \
    -p "${OLLAMA_PORT}:11434" \
    -e NVIDIA_VISIBLE_DEVICES="${NVIDIA_VISIBLE_DEVICES}" \
    -e NVIDIA_DRIVER_CAPABILITIES="${NVIDIA_DRIVER_CAPABILITIES}" \
    -v "${OLLAMA_MODELS_DIR}:/root/.ollama" \
    ollama/ollama serve
  
  echo "Waiting for Ollama to start..."
  sleep 10
  
  # Verify Ollama is accessible
  if ! curl -s "http://localhost:${OLLAMA_PORT}/api/tags" >/dev/null 2>&1; then
    echo "ERROR: Ollama still not accessible at localhost:${OLLAMA_PORT}"
    echo "Check container logs with: docker logs ${CONTAINER_NAME}"
    exit 1
  fi
fi

echo "Ollama is running successfully!"
echo ""
echo "Ollama API endpoint: http://localhost:${OLLAMA_PORT}"
echo ""
echo "Example usage:"
echo "  # List available models"
echo "  curl http://localhost:${OLLAMA_PORT}/api/tags"
echo ""
echo "  # Pull a model (e.g., llama3.2)"
echo "  curl -X POST http://localhost:${OLLAMA_PORT}/api/pull -d '{\"name\": \"llama3.2\"}'"
echo ""
echo "  # Generate text"
echo "  curl -X POST http://localhost:${OLLAMA_PORT}/api/generate -d '{\"model\": \"llama3.2\", \"prompt\": \"Hello world!\"}'"
echo ""
echo "Container management:"
echo "  # Check status: docker ps | grep ${CONTAINER_NAME}"
echo "  # View logs: docker logs ${CONTAINER_NAME}"
echo "  # Stop: docker stop ${CONTAINER_NAME}"
echo ""
echo "SSH tunnel (if accessing remotely):"
echo "  ssh -L ${OLLAMA_PORT}:localhost:${OLLAMA_PORT} user@cluster-host"
