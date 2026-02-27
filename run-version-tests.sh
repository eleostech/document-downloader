#!/bin/bash

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

# Run tests for PS6
echo "Running tests in PowerShell 6..."
docker-compose -f docker-compose.versions.yml run --rm downloader-ps6
RESULT_PS6=$?

# Run tests for PS7
echo "Running tests in PowerShell 7..."
docker-compose -f docker-compose.versions.yml run --rm downloader-ps7
RESULT_PS7=$?

# Tear down
echo "Cleaning up..."
docker-compose -f docker-compose.versions.yml stop

echo "-----------------------------------"
echo "Results:"
echo "PowerShell 6: $([ $RESULT_PS6 -eq 0 ] && echo 'PASSED' || echo 'FAILED')"
echo "PowerShell 7: $([ $RESULT_PS7 -eq 0 ] && echo 'PASSED' || echo 'FAILED')"
echo "-----------------------------------"

if [ $RESULT_PS6 -ne 0 ] || [ $RESULT_PS7 -ne 0 ]; then
    exit 1
fi
exit 0
