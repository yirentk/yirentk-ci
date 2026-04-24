#!/usr/bin/env bash

set -euo pipefail

if [ "$#" -ne 3 ]; then
  echo "usage: $0 <release_dir> <namespace> <host_port>" >&2
  exit 1
fi

release_dir="$1"
namespace="$2"
host_port="$3"

sudo ctr -n k8s.io images import "${release_dir}/yirentk-image.tar"

kubectl apply -f "${release_dir}/namespace.yaml"

kubectl -n "${namespace}" create secret generic yirentk-config \
  --from-file=config.toml="${release_dir}/config.toml" \
  --dry-run=client \
  -o yaml | kubectl apply -f -

kubectl apply -f "${release_dir}/pvc.yaml"
kubectl apply -f "${release_dir}/service.yaml"
kubectl apply -f "${release_dir}/deployment.yaml"

kubectl -n "${namespace}" rollout status deploy/yirentk --timeout=240s
kubectl -n "${namespace}" get pvc,pod,svc,deploy

curl --fail --silent --show-error "http://127.0.0.1:${host_port}/api/healthz"
curl --fail --silent --show-error --head "http://127.0.0.1:${host_port}/"
