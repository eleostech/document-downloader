#!/bin/bash

# Ensure we start fresh
echo "Stopping any existing containers..."
docker-compose down --remove-orphans

# Build and start the services
echo "Building and starting MockServer..."
docker-compose up --build -d mockserver

echo "Waiting for MockServer to become healthy..."
# Wait for health status
for i in {1..30}; do
    STATUS=$(docker inspect --format='{{.State.Health.Status}}' $(docker-compose ps -q mockserver))
    if [ "$STATUS" == "healthy" ]; then
        break
    fi
    sleep 2
done

if [ "$STATUS" != "healthy" ]; then
    echo "MockServer failed to become healthy."
    docker-compose logs mockserver
    exit 1
fi

# Run the tests
echo "MockServer is healthy! Running tests..."
docker-compose run --rm downloader pwsh -c "Invoke-Pester -Path Tests/doc-downloader.tests.ps1, Tests/drive-axle-doc-downloader.tests.ps1"
RESULT=$?

# ALWAYS print logs if result is not 0
if [ $RESULT -ne 0 ]; then
    echo "Tests failed. MockServer logs:"
    docker-compose logs mockserver
fi

# Tear down - just stop, don't down yet
echo "Cleaning up..."
docker-compose stop
exit $RESULT
