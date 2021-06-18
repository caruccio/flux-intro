# Baixar binarios

```
curl -skL https://storage.googleapis.com/kubernetes-release/release/v1.19.10/bin/linux/amd64/kubectl > bin/kubectl
curl -sL https://github.com/kubernetes-sigs/kind/releases/download/v0.11.1/kind-linux-amd64 > bin/kind
curl -sL https://github.com/kubernetes-sigs/kustomize/releases/download/kustomize%2Fv4.1.3/kustomize_v4.1.3_linux_amd64.tar.gz | tar xzv -C bin/ kustomize
curl -sL https://github.com/instrumenta/kubeval/releases/latest/download/kubeval-linux-amd64.tar.gz | tar xzv -C bin/ kubeval
curl -sL https://github.com/fluxcd/flux2/releases/download/v0.14.2/flux_0.14.2_linux_amd64.tar.gz | tar xzv -C bin flux
curl -skL https://get.helm.sh/helm-v3.2.4-linux-amd64.tar.gz | tar xz -C bin --transform=s,.*,helm, linux-amd64/helm

chmod +x bin/*
export PATH=$PWD/bin:$PATH
```

# Criar cluster Kind

```
kind create cluster --name flux # --config kindconfig.yaml
kubectl get node -w
```

# Instalar Flux2

```
flux install
kubectl get pod -A
kubectl get crds | grep fluxcd
kubectl api-resources | grep fluxcd

## kubens flux-system
kubectl config set contexts.$(kubectl config current-context).namespace flux-system
```

# HelmRepository

```
flux create source helm bitnami --url=https://charts.bitnami.com/bitnami ### --export
flux create source helm ingress-nginx --url=https://kubernetes.github.io/ingress-nginx ### --export
kubectl get -A helmrepo
```
> mostrar repositorio dentro do pod do source-controller

>> mostrar md5sum com formatacao flux
>> mostrar interval

# HelmRelease

```
DOCKER_CIDR=$(docker network inspect kind --format '{{(index .IPAM.Config 0).Subnet}}')
echo $DOCKER_CIDR

METALLB_RANGE=$(printf "%s-%s" $(cut -f1-2 -d. <<<$DOCKER_CIDR){.100.0,.200.0})
echo $METALLB_RANGE

sed -e "s/__METALLB_RANGE__/$METALLB_RANGE/" metallb-values.yaml.tpl > metallb-values.yaml
cat metallb-values.yaml

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

kubectl describe hr/metallb
kubectl get hr -w
flux get hr
helm ls -A
```

```
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

kubectl get hr -w
kubectl describe hr/ingress-nginx

kubectl get svc -n ingress-nginx -w
INGRESS_IP=$(kubectl get service -n ingress-nginx ingress-nginx-ingress-nginx-controller -o jsonpath={.status.loadBalancer.ingress[0].ip})
echo $INGRESS_IP
```

```
kubectl edit hr/ingress-nginx
# udpate version 3.30.0
watch flux get hr
```

> mostrar charts dentro do pod do source-controller

# GitRepository

```
flux create source git app --url https://github.com/caruccio/flux-intro.git --branch main
kubectl get gitrepo -A
flux get source git
```

## Simple app

```
flux create kustomization simple --source GitRepository/app --path /simple
kubectl get ks,gitrepo
flux get ks

curl --resolve kind.io:80:$INGRESS_IP http://kind.io/
```

```
kubectl delete ks simple -n flux-system
kubectl delete deploy,svc,ing --all -n default
```

## Kustomize

```
cd kustomize
grep ^ base/ -r

grep ^ hlg/ -r
kustomize build hlg/ > hlg.yaml

grep ^ prd/ -r
kustomize build prd/ > prd.yaml

diff -pu hlg.yaml prd.yaml

cd ../
```

## Complex app

```
cd complex/
cat bootstrap/hlg.yaml
kubectl apply -f bootstrap/hlg.yaml

kubectl get ks -n flux-system
kubectl get deploy,svc,ing -n default

kubectl delete deploy/nginx svc/nginx ing/nginx -n default
watch kubectl get deploy,svc,ing -n default

kubectl delete ks/app -n flux-system
kubectl get deploy,svc,ing -n default
```

# Cleanup

```
cd ..
bash reset.sh
```

# Image Automation

```
cd images/

flux install --components-extra=image-automation-controller,image-reflector-controller
kubectl get pod -A
kubectl get crds | grep fluxcd | egrep '^|.*image.*'
kubectl api-resources | grep fluxcd | egrep '^|.*image.*'

flux get source all
flux get ks
flux get hr
```

```
export DOCKER_REPO=XXX ## <----- Docker Hub username -----

make release APP_VERSION=1.0.0 DOCKER_REPO=$DOCKER_REPO
make run APP_VERSION=1.0.0 DOCKER_REPO=$DOCKER_REPO
docker ps
curl 127.0.0.1:8080
make stop
```

```
cat imagerepo.yaml
kubectl apply -f imagerepo.yaml
flux get image all

cat imagepolicy.yaml
kubectl apply -f imagepolicy.yaml
flux get image all
```

```
export GITHUB_USERNAME=caruccio
export GITHUB_PASSWORD=XXXXXXXX ## ---> https://github.com/settings/tokens (scope=repo)

flux create source git app \
    --url https://github.com/caruccio/flux-intro.git \
    --branch main \
    --username "$GITHUB_USERNAME" \
    --password "$GITHUB_PASSWORD"

flux get source git
kubectl describe secret app

flux create kustomization app \
    --source GitRepository/app \
    --path /images/app

flux get ks
kubectl get deployment app -n default -o wide
```

```
cat imageupdateautomation.yaml
kubectl apply -f imageupdateautomation.yaml
flux get image all
```

```
make release APP_VERSION=1.0.1 DOCKER_REPO=$DOCKER_REPO

flux reconcile image repository app
flux get image all
kubectl describe deployment app -n default
```

```
kubectl get deploy -n default -w   ## <---- outro terminal

make release APP_VERSION=1.0.2 DOCKER_REPO=$DOCKER_REPO
flux reconcile image repository app
```

