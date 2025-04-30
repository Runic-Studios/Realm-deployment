#!/bin/bash
set -euo pipefail

# Assumes you have forwarding.secret in this dir with a plaintext password

# Check if forwarding.secret file exists
if [[ ! -f forwarding.secret ]]; then
  echo "Missing forwarding.secret file"
  exit 1
fi

kubectl create secret generic velocity-forwarding-secret \
  --namespace placeholder \
  --from-file=forwarding.secret=forwarding.secret \
  --dry-run=client \
  -o json > velocity.json

kubeseal \
  --format yaml \
  --scope namespace-wide \
  --cert pub-cert.pem \
  --controller-name=sealed-secrets \
  --controller-namespace=sealed-secrets \
  < velocity.json > forwarding-secret-sealed.yaml

rm velocity.json

sed -i 's/^\(\s*\)namespace: placeholder/\1namespace: {{ .Values.namespace }}/' forwarding-secret-sealed.yaml

mv forwarding-secret-sealed.yaml ../templates/velocity

echo "Generated templates/velocity/forwarding-secret-sealed.yaml"
