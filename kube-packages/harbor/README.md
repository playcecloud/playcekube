# harbor 설치

private helm repo 에 있는 chart 를 이용하여 설치

## 패키지 정보

<!-- Addons Package List Start -->
- harbor 2.5.0
- docker.io/bitnami/chartmuseum:0.14.0-debian-10-r74
- docker.io/bitnami/harbor-adapter-trivy:2.5.0-debian-10-r8
- docker.io/bitnami/harbor-core:2.5.0-debian-10-r8
- docker.io/bitnami/harbor-jobservice:2.4.2-debian-10-r31
- docker.io/bitnami/harbor-notary-server:2.5.0-debian-10-r8
- docker.io/bitnami/harbor-notary-signer:2.5.0-debian-10-r7
- docker.io/bitnami/harbor-portal:2.5.0-debian-10-r9
- docker.io/bitnami/harbor-registry:2.5.0-debian-10-r7
- docker.io/bitnami/harbor-registryctl:2.5.0-debian-10-r8
- docker.io/bitnami/nginx:1.21.6-debian-10-r80
- docker.io/bitnami/postgresql:11.15.0-debian-10-r68
- docker.io/bitnami/redis:6.2.6-debian-10-r179
<!-- Addons Package List End -->

## 공통 준비작업

```ShellSession
git clone https://github.com/playcecloud/playcekube.git
cd playcekube
cd kube-packages/harbor
```

## 설치

### harbor install shell

persistent 설정을 false 로 하고 사설 인증서 사용

```ShellSession
# install
/playcecloud/playcekube/kube-packages/harbor/install-helm-charts.sh
```

또는 values.yaml 파일을 설정에 맞게 수정한 후 아래의 커맨드로 설치

```ShellSession
# copy installed-values.yaml
cp -rp /playcecloud/playcekube/kube-packages/harbor/values.yaml /playcecloud/playcekube/kube-packages/harbor/installed-values.yaml

# installed-values.yaml 파일을 수정

# create namespace
kubectl create ns harbor

# harbor install
helm install harbor playcekube/harbor -n harbor -f /playcecloud/playcekube/kube-packages/harbor/installed-values.yaml
```

## 설치 확인

dns 서버를 deploy 서버를 지정하거나 hosts 파일에 ingress 서버 주소를 바라보도록 설정하여  
웹브라우저에서 확인  
  
이후 https://harbor.playcek8s.playcekube.local 로 접속하시면 확인 가능

