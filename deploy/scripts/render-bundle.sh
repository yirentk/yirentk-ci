#!/usr/bin/env bash

set -euo pipefail

if [ "$#" -ne 8 ]; then
  echo "usage: $0 <release_dir> <image_ref> <server_host> <host_port> <auth_secret> <database_dsn> <model_base_url> <model_api_key>" >&2
  exit 1
fi

release_dir="$1"
image_ref="$2"
server_host="$3"
host_port="$4"
auth_secret="$5"
database_dsn="$6"
model_base_url="$7"
model_api_key="$8"

reject_placeholder_secret() {
  local name="$1"
  local value="$2"
  local normalized
  normalized="$(printf '%s' "$value" | tr '[:upper:]' '[:lower:]')"

  case "$normalized" in
    *placeholder*|*replace-with*|*your-api-key*)
      echo "${name} is still a placeholder; configure the real GitHub secret before deploying" >&2
      exit 1
      ;;
  esac
}

reject_placeholder_secret "AUTH_SECRET" "${auth_secret}"
reject_placeholder_secret "MODEL_API_KEY" "${model_api_key}"

template_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/k8s"

mkdir -p "${release_dir}"

cp "${template_root}/namespace.yaml" "${release_dir}/namespace.yaml"
cp "${template_root}/pvc.yaml" "${release_dir}/pvc.yaml"
cp "${template_root}/service.yaml" "${release_dir}/service.yaml"
cp "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/remote-apply.sh" "${release_dir}/remote-apply.sh"
chmod +x "${release_dir}/remote-apply.sh"

sed \
  -e "s|__IMAGE__|${image_ref}|g" \
  -e "s|__HOST_PORT__|${host_port}|g" \
  "${template_root}/deployment.yaml.tmpl" > "${release_dir}/deployment.yaml"

sed \
  -e "s|__SERVER_HOST__|${server_host}|g" \
  -e "s|__HOST_PORT__|${host_port}|g" \
  -e "s|__AUTH_SECRET__|${auth_secret}|g" \
  -e "s|__DATABASE_DSN__|${database_dsn}|g" \
  -e "s|__MODEL_BASE_URL__|${model_base_url}|g" \
  -e "s|__MODEL_API_KEY__|${model_api_key}|g" \
  "${template_root}/config.toml.tmpl" > "${release_dir}/config.toml"
