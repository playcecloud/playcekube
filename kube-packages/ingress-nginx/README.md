# ingress-nginx

서비스 매쉬

## 패키지 정보

<!-- Addons Package List Start -->
- ingress-nginx 1.1.3
- k8s.gcr.io/ingress-nginx/controller:v1.1.3@sha256:31f47c1e202b39fadecf822a9b76370bd4baed199a005b3e7d4d1455f4fd3fe2
- k8s.gcr.io/ingress-nginx/kube-webhook-certgen:v1.1.1@sha256:64d8c73dca984af206adf9d6d7e46aa550362b1d7a01f3a0a91b20cc67868660
<!-- Addons Package List End -->

## 공통 준비작업

```ShellSession
git clone https://github.com/playcecloud/playcekube.git
cd playcekube
cd kube-packages/ingress-nginx
```

## 설치

### ingress-nginx install shell

```ShellSession
# install
/playcecloud/playcekube/kube-packages/ingress-nginx/install-helm-charts.sh
```

또는 values.yaml 파일을 설정에 맞게 수정한 후 아래의 커맨드로 설치

```ShellSession
# copy installed-values.yaml
cp -rp /playcecloud/playcekube/kube-packages/ingress-nginx/values.yaml /playcecloud/playcekube/kube-packages/ingress-nginx/installed-values.yaml

# installed-values.yaml 파일을 수정
# class2-values.yaml 파일을 수정
#controller.ingressClassResource.name
#controller.ingressClassResource.controllerValue
#controller.ingressClass
#controller.hostPort.ports.http
#controller.hostPort.ports.https

# create namespace
kubectl create ns ingress-nginx

# ingress-nginx install
helm install ingress-nginx playcekube/ingress-nginx -n ingress-nginx -f /playcecloud/playcekube/kube-packages/ingress-nginx/installed-values.yaml
# or other class
helm upgrade -i ingress-nginx2 playcekube/ingress-nginx -f class2-values.yaml -n ingress-nginx
```

