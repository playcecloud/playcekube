# curl 설치

private helm repo 에 있는 chart 를 이용하여 설치

## 공통 준비작업

```ShellSession
git clone -b dev https://github.com/OpenSourceConsulting/PlayceKube.git
cd PlayceKube
cd kube-packages/curl
```

## 설치

### curl install shell

```ShellSession
# install
/playcecloud/playcekube/kube-packages/curl/install-helm-charts.sh
```

또는 values.yaml 파일을 설정에 맞게 수정한 후 아래의 커맨드로 설치

```ShellSession
# copy installed-values.yaml
cp -rp /playcecloud/playcekube/kube-packages/curl/values.yaml /playcecloud/playcekube/kube-packages/curl/installed-values.yaml

# installed-values.yaml 파일을 수정

# curl install
helm install curl playcekube/curl -n default -f /playcecloud/playcekube/kube-packages/curl/installed-values.yaml
```

## 설치 확인

```ShellSession
kubectl get pod -n default
```

