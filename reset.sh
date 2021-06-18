#!/bin/bash

kind delete cluster --name flux
kind create cluster --name flux

flux install
flux create source helm bitnami --url=https://charts.bitnami.com/bitnami
flux create source helm ingress-nginx --url=https://kubernetes.github.io/ingress-nginx
kubectl config set contexts.$(kubectl config current-context).namespace flux-system

DOCKER_CIDR=$(docker network inspect kind --format '{{(index .IPAM.Config 0).Subnet}}')
METALLB_RANGE=$(printf "%s-%s" $(cut -f1-2 -d. <<<$DOCKER_CIDR){.100.0,.200.0})
sed -e "s/__METALLB_RANGE__/$METALLB_RANGE/" metallb-values.yaml.tpl > metallb-values.yaml

kubectl apply -f - <<EOF
$(flux create hr metallb \
        --chart metallb \
        --chart-version 2.0.2 \
        --source HelmRepository/bitnami \
        --target-namespace metallb-system \
        --values ./metallb-values.yaml \
        --export)
  install:
    createNamespace: true
EOF

kubectl apply -f - <<EOF
$(flux create hr ingress-nginx \
    --chart ingress-nginx \
    --chart-version 3.25.0 \
    --source HelmRepository/ingress-nginx \
    --target-namespace ingress-nginx \
    --export)
  install:
    createNamespace: true
  values:
    defaultBackend:
      enabled: true
EOF

until kubectl get svc -n ingress-nginx ingress-nginx-ingress-nginx-controller 2>/dev/null; do
  echo -n .
  sleep 1
done
echo

echo  "Ingress IP:" $(kubectl get service -n ingress-nginx ingress-nginx-ingress-nginx-controller -o jsonpath={.status.loadBalancer.ingress[0].ip})
