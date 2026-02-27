#!/bin/bash

# This script runs tests for a specific PowerShell version using Docker Compose.
# Usage: ./run-version-tests.sh [downloader-ps6|downloader-ps7]

SERVICE_NAME=$1

if [ -z "$SERVICE_NAME" ]; then
    echo "Usage: $0 [downloader-ps6|downloader-ps7]"
    exit 1
fi

# Ensure we start fresh
echo "Stopping any existing containers..."
docker-compose -f docker-compose.versions.yml down --remove-orphans

# Build and start the mockserver
echo "Building and starting MockServer..."
docker-compose -f docker-compose.versions.yml up --build -d mockserver

echo "Waiting for MockServer to become healthy..."
for i in {1..30}; do
    STATUS=$(docker inspect --format='{{.State.Health.Status}}' $(docker-compose -f docker-compose.versions.yml ps -q mockserver))
    if [ "$STATUS" == "healthy" ]; then
        break
    fi
    sleep 2
done

if [ "$STATUS" != "healthy" ]; then
    echo "MockServer failed to become healthy."
    docker-compose -f docker-compose.versions.yml logs mockserver
    exit 1
fi

echo "MockServer is healthy!"

# Run tests for the specified service
echo "Running tests in $SERVICE_NAME..."
docker-compose -f docker-compose.versions.yml run --rm $SERVICE_NAME
RESULT=$?

# Tear down
echo "Cleaning up..."
docker-compose -f docker-compose.versions.yml stop

if [ $RESULT -ne 0 ]; then
    echo "Tests FAILED for $SERVICE_NAME"
    exit 1
fi

echo "Tests PASSED for $SERVICE_NAME"
exit 0
