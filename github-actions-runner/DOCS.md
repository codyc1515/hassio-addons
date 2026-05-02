# GitHub Actions Runner

Run a GitHub Actions self-hosted runner as a Home Assistant app.

## Configuration

Required options:

- `github_url`: GitHub repository or organization URL
- `runner_token`: Runner registration token from GitHub (used for initial registration)

Optional options:

- `runner_name`: Defaults to `homeassistant` when omitted
- `runner_labels`: Defaults to `self-hosted,linux,docker` when omitted
- `runner_workdir`: Defaults to `_work` when omitted

## Notes

- This app uses image `ghcr.io/codyc1515/github-actions-runner` with version `latest`.
- The runner is persistent: container restarts do not auto-remove or re-register it.
- After first successful registration, the runner starts from existing local config and does not need a fresh token on normal reconnect/restart.
- Docker socket is expected for Docker-based job execution.
- If Home Assistant logs `401`/`403` pull errors from GHCR, confirm the publish workflow succeeded and package visibility is set to `Public`.
- The image pre-seeds Python in the GitHub Actions toolcache (`3.11.15` by default) so `actions/setup-python` can resolve `3.11` without a runtime download.
