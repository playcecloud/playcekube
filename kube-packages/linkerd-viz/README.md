# linkerd-viz

서비스 매쉬

## 공통 준비작업

```ShellSession
git clone https://github.com/playcecloud/playcekube.git
cd PlayceKube
cd kube-packages/linkerd-viz
```

## 설치

### linkerd-viz install shell

사설 registry 서버 사용하도록 values.yaml 수정

```ShellSession
# install
/playcecloud/playcekube/kube-packages/linkerd-viz/install-helm-charts.sh
```

또는 values.yaml 파일을 설정에 맞게 수정한 후 아래의 커맨드로 설치

```ShellSession
# copy installed-values.yaml
cp -rp /playcecloud/playcekube/kube-packages/linkerd-viz/values.yaml /playcecloud/playcekube/kube-packages/linkerd-viz/installed-values.yaml

# installed-values.yaml 파일을 수정

# create namespace
kubectl create ns linkerd-viz

# harbor install
helm install linkerd-viz playcekube/linkerd-viz -n linkerd-viz -f /playcecloud/playcekube/kube-packages/linkerd-viz/installed-values.yaml
```

