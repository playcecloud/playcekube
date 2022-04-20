# kubeapps 설치

private helm repo 에 있는 chart 를 이용하여 설치

## 패키지 정보

<!-- Addons Package List Start -->
- kubeapps 2.4.4
- docker.io/bitnami/kubeapps-apis:2.4.4-debian-10-r18
- docker.io/bitnami/kubeapps-apprepository-controller:2.4.4-scratch-r1
- docker.io/bitnami/kubeapps-asset-syncer:2.4.3-scratch-r2
- docker.io/bitnami/kubeapps-asset-syncer:2.4.4-scratch-r1
- docker.io/bitnami/kubeapps-dashboard:2.4.4-debian-10-r11
- docker.io/bitnami/kubeapps-kubeops:2.4.4-scratch-r1
- docker.io/bitnami/nginx:1.21.6-debian-10-r80
- docker.io/bitnami/postgresql:14.2.0-debian-10-r67
<!-- Addons Package List End -->

## 공통 준비작업

```ShellSession
git clone https://github.com/playcecloud/playcekube.git
cd playcekube
cd kube-packages/kubeapps
```

## 설치

### kubeapps install shell

persistent 설정을 false 로 하고 사설 인증서 사용

```ShellSession
# install
/playcecloud/playcekube/kube-packages/kubeapps/install-helm-charts.sh
```

또는 values.yaml 파일을 설정에 맞게 수정한 후 아래의 커맨드로 설치

```ShellSession
# copy installed-values.yaml
cp -rp /playcecloud/playcekube/kube-packages/kubeapps/values.yaml /playcecloud/playcekube/kube-packages/kubeapps/installed-values.yaml

# installed-values.yaml 파일을 수정

# create namespace
kubectl create ns kubeapps

# kubeapps install
helm install kubeapps playcekube/kubeapps -n kubeapps -f /playcecloud/playcekube/kube-packages/kubeapps/installed-values.yaml
```

## 설치 확인

dns 서버를 deploy 서버를 지정하거나 hosts 파일에 ingress 서버 주소를 바라보도록 설정하여  
웹브라우저에서 확인  
  
이후 https://kubeapps.playcek8s.playcekube.local 로 접속하시면 확인 가능

