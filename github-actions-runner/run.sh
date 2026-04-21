#!/usr/bin/env bash
set -euo pipefail

cd /home/runner/actions-runner

# Home Assistant add-on fallback:
# if env vars are missing, load values from /data/options.json.
SUPERVISOR_OPTIONS_JSON=""

load_supervisor_options() {
  if [[ -n "${SUPERVISOR_OPTIONS_JSON}" ]]; then
    return
  fi

  if [[ -z "${SUPERVISOR_TOKEN:-}" ]]; then
    SUPERVISOR_OPTIONS_JSON="{}"
    return
  fi

  local response
  response="$(curl -fsSL \
    -H "Authorization: Bearer ${SUPERVISOR_TOKEN}" \
    http://supervisor/addons/self/info 2>/dev/null || true)"

  SUPERVISOR_OPTIONS_JSON="$(printf '%s' "${response}" | jq -c '.data.options // {}' 2>/dev/null || true)"
  SUPERVISOR_OPTIONS_JSON="${SUPERVISOR_OPTIONS_JSON:-{}}"
}

read_option() {
  local key="$1"
  local value=""

  if [[ -r /data/options.json ]]; then
    value="$(jq -r ".${key} // empty" /data/options.json 2>/dev/null || true)"
  else
    load_supervisor_options
    value="$(printf '%s' "${SUPERVISOR_OPTIONS_JSON}" | jq -r --arg key "${key}" '.[$key] // empty' 2>/dev/null || true)"
  fi

  printf '%s' "${value}"
}

GITHUB_URL="${GITHUB_URL:-$(read_option github_url)}"
RUNNER_TOKEN="${RUNNER_TOKEN:-$(read_option runner_token)}"
RUNNER_NAME="${RUNNER_NAME:-$(read_option runner_name)}"
RUNNER_LABELS="${RUNNER_LABELS:-$(read_option runner_labels)}"
RUNNER_WORKDIR="${RUNNER_WORKDIR:-$(read_option runner_workdir)}"

if [[ -z "${GITHUB_URL:-}" ]]; then
  echo "GITHUB_URL is required"
  exit 1
fi

if [[ -z "${RUNNER_TOKEN:-}" ]]; then
  echo "RUNNER_TOKEN is required"
  exit 1
fi

RUNNER_NAME="${RUNNER_NAME:-homeassistant}"
RUNNER_WORKDIR="${RUNNER_WORKDIR:-_work}"
RUNNER_LABELS="${RUNNER_LABELS:-self-hosted,linux,docker}"

cleanup() {
  echo "Removing runner..."
  ./config.sh remove --unattended --token "${RUNNER_TOKEN}" || true
}
trap cleanup EXIT INT TERM

if [[ ! -f .runner ]]; then
  echo "Configuring runner..."
  ./config.sh \
    --url "${GITHUB_URL}" \
    --token "${RUNNER_TOKEN}" \
    --name "${RUNNER_NAME}" \
    --work "${RUNNER_WORKDIR}" \
    --labels "${RUNNER_LABELS}" \
    --unattended \
    --replace
fi

echo "Starting runner..."
exec ./run.sh
