# Eleos/Drive Axle Document Downloader

If you're just looking to download the script, you can [download the latest release](https://github.com/eleostech/document-downloader/releases). Instructions for configuring the script are available in the package.

If you prefer not to use the script, you can always use the REST documents API directly. For more information about the Eleos Document API, see the [Platform documentation.](https://dev.eleostech.com/platform/platform.html#tag/Documents)

## Proposing changes and contributing

We welcome [pull requests](https://github.com/eleostech/document-downloader/pulls) that fix bugs or add widely-applicable features *and* preserve or extend the automated test coverage.

## Running tests locally
### Powershell v6 & v7
For running tests using Powershell v6 and v7, you can use the provided Docker and Docker Compose setup.

- ```docker compose up run-powershell-6-unit-tests --build```
- ```docker compose up run-powershell-6-integration-tests --build```
- ```docker compose up run-powershell-7-unit-tests --build```
- ```docker compose up run-powershell-7-integration-tests --build```

### Powershell v5
If you need to test on Powershell v5 you can still run the same unit and integration tests provided, except there isn't a Dockerfile to do this in this repository. See the ```.circleci/config.yml``` for steps/commands on how to run the tests without Docker.

**Note: Because the tests are not setup to run Powershell v5 inside of Docker you will have to have Powershell v5 available on your computer or setup a Dockerfile for it yourself**
