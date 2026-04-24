#!/usr/bin/env bash

set -euo pipefail

if [ "$#" -ne 5 ]; then
  echo "usage: $0 <release_dir> <image_ref> <server_host> <host_port> <auth_secret>" >&2
  exit 1
fi

release_dir="$1"
image_ref="$2"
server_host="$3"
host_port="$4"
auth_secret="$5"

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
  "${template_root}/config.toml.tmpl" > "${release_dir}/config.toml"
