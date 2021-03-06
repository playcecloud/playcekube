# linkerd-multicluster

서비스 매쉬 addon

## 패키지 정보

<!-- Addons Package List Start -->
- linkerd-multicluster stable-2.11.1
- gcr.io/google_containers/pause
<!-- Addons Package List End -->

## 공통 준비작업

```ShellSession
git clone https://github.com/playcecloud/playcekube.git
cd playcekube
cd kube-packages/linkerd-multicluster
```

## 설치

### linkerd-multicluster install shell

사설 registry 서버 사용하도록 values.yaml 수정

```ShellSession
# install
/playcecloud/playcekube/kube-packages/linkerd-multicluster/install-helm-charts.sh
```

또는 values.yaml 파일을 설정에 맞게 수정한 후 아래의 커맨드로 설치

```ShellSession
# copy installed-values.yaml
cp -rp /playcecloud/playcekube/kube-packages/linkerd-multicluster/values.yaml /playcecloud/playcekube/kube-packages/linkerd-multicluster/installed-values.yaml

# installed-values.yaml 파일을 수정

# create namespace
kubectl create ns linkerd-multicluster

# harbor install
helm install linkerd-multicluster playcekube/linkerd-multicluster -n linkerd-multicluster -f /playcecloud/playcekube/kube-packages/linkerd-multicluster/installed-values.yaml
```

