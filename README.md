# GitHub Actions Runner

This repository provides a Home Assistant app named **GitHub Actions Runner**.

## App files

- `repository.yaml`
- `github-actions-runner/config.yaml`
- `github-actions-runner/Dockerfile`
- `github-actions-runner/run.sh`

## Install in Home Assistant

1. In Home Assistant, go to `Settings -> Add-ons -> Add-on Store`.
2. Open the overflow menu (`...`) and choose `Repositories`.
3. Add this repository URL:
   - `https://github.com/codyc1515/hassio-addons`
4. Find and install **GitHub Actions Runner**.

## Configure app options

Required:

- `github_url`
- `runner_token` (used for initial registration)

Optional:

- `runner_name` (defaults to `homeassistant` if omitted)
- `runner_labels` (defaults to `self-hosted,linux,docker` if omitted)
- `runner_workdir` (defaults to `_work` if omitted)

## Start

Start the app from Home Assistant.

The runner is now persistent across restarts. It is not auto-removed on container stop, so normal disconnects/restarts do not require re-registration or a new token.

The container image defaults to:
- `ghcr.io/codyc1515/github-actions-runner:latest`

## Image publishing

This repo includes a workflow that publishes the app image to GHCR:
- `.github/workflows/publish-github-actions-runner.yml`

It publishes multi-arch `linux/amd64` and `linux/arm64` images.
