# Baixar binarios

```
BIN_DIR=/usr/local/bin/

curl -sL https://github.com/kubernetes-sigs/kind/releases/download/v0.11.1/kind-linux-amd64 > kind
sudo install -v --mode=755 kind $BIN_DIR
rm -f kind

curl -sL https://github.com/kubernetes-sigs/kustomize/releases/download/kustomize%2Fv4.1.3/kustomize_v4.1.3_linux_amd64.tar.gz \
    | tar xzf - kustomize
sudo install --mode=755 kustomize $BIN_DIR
rm -f kustomize

curl -sL https://github.com/instrumenta/kubeval/releases/latest/download/kubeval-linux-amd64.tar.gz \
    | tar xzf kubeval-linux-amd64.tar.gz kubeval
sudo install --mode=755 kubeval $BIN_DIR
rm -f kubeval

curl -sL https://github.com/fluxcd/flux2/releases/download/v0.14.2/flux_0.14.2_linux_amd64.tar.gz \
    | tar xzf - flux
sudo install --mode=755 flux $BIN_DIR
rm -f flux
```

# Criar cluster KinD

```
kind create cluster --name flux # --config kindconfig.yaml
```

# Instalar Flux2

```
flux install ## --components-extra=image-automation-controller,image-reflector-controller
kubectl get pod -A
kubectl get crds | grep fluxcd
kubectl api-resources | grep fluxcd
```

# HelmRepository

```
flux create source helm bitnami --url=https://charts.bitnami.com/bitnami ### --export
flux create source helm ingress-nginx --url=https://kubernetes.github.io/ingress-nginx ### --export
kubectl get -A helmrepo
```
> mostrar repositorio dentro do pod do source-controller

# HelmRelease

```
# kubens flux-system
kubectl config set contexts.$(kubectl config current-context).namespace flux-system

cat metallb-values.yaml
kubectl apply -f - <<EOF
$(flux create hr metallb --chart metallb --chart-version 2.0.2 --source HelmRepository/bitnami --target-namespace metallb-system  --values ./metallb-values.yaml  --export)
  install:
    createNamespace: true
EOF

kubectl get hr
kubectl describe hr/metallb
helm ls -A
```

```
kubectl apply -f - <<EOF
$(flux create hr ingress-nginx --chart ingress-nginx --chart-version 3.25.0 --source HelmRepository/ingress-nginx --target-namespace ingress-nginx --export)
  install:
    createNamespace: true
EOF

kubectl get hr
kubectl describe hr/ingress-nginx
```

```
kubectl edit hr/ingress-nginx
# udpate version 3.30.0
```

# GitRepository

```
flux create source git app --url https://github.com/caruccio/flux-intro.git --branch main
```

# Kustomization

```
git clone https://github.com/caruccio/flux-intro.git
```

### Simple app

```
flux create kustomization simple --source GitRepository/app --path /simple
kubectl get ks,gitrepo -A

INGRESS_IP=$(kubectl get service -n ingress-nginx ingress-nginx-ingress-nginx-controller -o jsonpath={.status.loadBalancer.ingress[0].ip})
echo $INGRESS_IP
curl --resolve kind.io:80:$INGRESS_IP http://kind.io/
```

```
kubectl delete ks simple -n flux-system
kubectl delete deploy,svc,ing --all -n default
```

### Multi Environment app

```

```
