# keepalived 설치

private helm repo 에 있는 chart 를 이용하여 설치  
kubernetes api 및 ingress vip 설정용 keepalived
별도의 로드밸런서가 있다면 사용할 필요가 없다

## 패키지 정보

<!-- Addons Package List Start -->
- keepalived 2.2.4
<!-- Addons Package List End -->

## 공통 준비작업

```ShellSession
git clone https://github.com/playcecloud/playcekube.git
cd playcekube
cd kube-packages/keepalived
```

## 설치

### keepalived install shell

```ShellSession
# install
/playcecloud/playcekube/kube-packages/keepalived/install-helm-charts.sh
```

또는 values.yaml 파일을 설정에 맞게 수정한 후 아래의 커맨드로 설치

```ShellSession
# copy installed-values.yaml
cp -rp /playcecloud/playcekube/kube-packages/keepalived/values.yaml /playcecloud/playcekube/kube-packages/keepalived/installed-values.yaml

# installed-values.yaml 파일을 수정

# keepalived install
helm install kubeapi-keepalived playcekube/keepalived -n kube-system -f /playcecloud/playcekube/kube-packages/keepalived/installed-values.yaml
```

## 설치 확인

```ShellSession
kubectl get pod -n kube-system
```

