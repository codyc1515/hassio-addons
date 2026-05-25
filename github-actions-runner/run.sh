#!/usr/bin/env bash
set -euo pipefail

RUNNER_HOME="/home/runner/actions-runner"
PERSIST_ROOT="/data/actions-runner"

if [[ "$(id -u)" = "0" ]]; then
  mkdir -p "${PERSIST_ROOT}"
  chown -R runner:runner "${PERSIST_ROOT}" "${RUNNER_HOME}"
  exec sudo -E -H -u runner /run.sh
fi

mkdir -p "${PERSIST_ROOT}"

# Keep runner registration state on /data so it survives container recreation.
for f in .credentials .credentials_rsaparams .runner .service; do
  if [[ -f "${PERSIST_ROOT}/${f}" && ! -f "${RUNNER_HOME}/${f}" ]]; then
    cp -f "${PERSIST_ROOT}/${f}" "${RUNNER_HOME}/${f}"
  fi
done

cd "${RUNNER_HOME}"

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

RUNNER_NAME="${RUNNER_NAME:-homeassistant}"
RUNNER_WORKDIR="${RUNNER_WORKDIR:-_work}"
RUNNER_LABELS="${RUNNER_LABELS:-self-hosted,linux,docker}"

if [[ ! -f .runner ]]; then
  if [[ -z "${RUNNER_TOKEN:-}" ]]; then
    echo "RUNNER_TOKEN is required for initial runner registration"
    exit 1
  fi

  echo "Configuring runner..."
  ./config.sh \
    --url "${GITHUB_URL}" \
    --token "${RUNNER_TOKEN}" \
    --name "${RUNNER_NAME}" \
    --work "${RUNNER_WORKDIR}" \
    --labels "${RUNNER_LABELS}" \
    --unattended \
    --replace

  for f in .credentials .credentials_rsaparams .runner .service; do
    if [[ -f "${f}" ]]; then
      cp -f "${f}" "${PERSIST_ROOT}/${f}"
    fi
  done
else
  echo "Runner already configured. Skipping registration."
fi

echo "Starting runner..."
exec ./run.sh
