#!/bin/bash

# This script runs tests for a specific PowerShell version using Docker Compose.
# Usage: ./run-version-tests.sh [downloader-ps5|downloader-ps6|downloader-ps7]

SERVICE_NAME=$1

if [ -z "$SERVICE_NAME" ]; then
    echo "Usage: $0 [downloader-ps5|downloader-ps6|downloader-ps7]"
    exit 1
fi

# Try 'docker compose' first, then 'docker-compose'
if docker compose version >/dev/null 2>&1; then
    COMPOSE_CMD="docker compose"
else
    COMPOSE_CMD="docker-compose"
fi

echo "Using compose command: $COMPOSE_CMD"

# Ensure we start fresh
echo "Stopping any existing containers..."
$COMPOSE_CMD -f docker-compose.versions.yml down --remove-orphans

# Build and run the specified service
echo "Building and running tests in $SERVICE_NAME..."
$COMPOSE_CMD -f docker-compose.versions.yml up --build --exit-code-from $SERVICE_NAME $SERVICE_NAME
RESULT=$?

# Tear down
echo "Cleaning up..."
$COMPOSE_CMD -f docker-compose.versions.yml stop

if [ $RESULT -ne 0 ]; then
    echo "Tests FAILED for $SERVICE_NAME"
    exit 1
fi

echo "Tests PASSED for $SERVICE_NAME"
exit 0
