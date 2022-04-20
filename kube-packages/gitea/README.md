# gitea 설치

private helm repo 에 있는 chart 를 이용하여 설치

## 패키지 정보

<!-- Addons Package List Start -->
- gitea 1.16.5
- docker.io/"gitea/gitea:1.16.5"
- docker.io/bitnami/memcached:1.6.9-debian-10-r114
- docker.io/bitnami/postgresql:11.11.0-debian-10-r62
- docker.io/library/busybox
<!-- Addons Package List End -->

## 공통 준비작업

```ShellSession
git clone https://github.com/playcecloud/playcekube.git
cd playcekube
cd kube-packages/gitea
```

## 설치

### gitea install shell

persistent 설정을 false 로 하고 사설 인증서 사용

```ShellSession
# install
/playcecloud/playcekube/kube-packages/gitea/install-helm-charts.sh
```

또는 values.yaml 파일을 설정에 맞게 수정한 후 아래의 커맨드로 설치

```ShellSession
# copy installed-values.yaml
cp -rp /playcecloud/playcekube/kube-packages/gitea/values.yaml /playcecloud/playcekube/kube-packages/gitea/installed-values.yaml

# installed-values.yaml 파일을 수정

# create namespace
kubectl create ns gitea

# gitea install
helm install gitea playcekube/gitea -n gitea -f /playcecloud/playcekube/kube-packages/gitea/installed-values.yaml
```

## 설치 확인

dns 서버를 deploy 서버를 지정하거나 hosts 파일에 ingress 서버 주소를 바라보도록 설정하여  
웹브라우저에서 확인  
  
이후 https://gitea.playcek8s.playcekube.local 로 접속하시면 확인 가능

