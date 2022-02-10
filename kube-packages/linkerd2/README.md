# linkerd2

서비스 매쉬

## 공통 준비작업

```ShellSession
git clone -b dev https://github.com/OpenSourceConsulting/PlayceKube.git
cd PlayceKube
cd kube-packages/linkerd2
```

## 설치

### linkerd2 install shell

사설 intermediateCA 인증서 사용  
사설 registry 서버 사용하도록 values.yaml 수정

```ShellSession
# install
/playcecloud/playcekube/kube-packages/linkerd2/install-helm-charts.sh
```

또는 values.yaml 파일을 설정에 맞게 수정한 후 아래의 커맨드로 설치

```ShellSession
# copy installed-values.yaml
cp -rp /playcecloud/playcekube/kube-packages/linkerd2/values.yaml /playcecloud/playcekube/kube-packages/linkerd2/installed-values.yaml

# installed-values.yaml 파일을 수정

# create namespace
kubectl create ns linkerd

# harbor install
helm install linkerd playcekube/linkerd2 -n linkerd -f /playcecloud/playcekube/kube-packages/linkerd2/installed-values.yaml
```

