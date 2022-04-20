# jenkins 설치

private helm repo 에 있는 chart 를 이용하여 설치

## 패키지 정보

<!-- Addons Package List Start -->
- jenkins 2.332.2
- docker.io/bats/bats:1.2.1
- docker.io/jenkins/inbound-agent:4.11.2-4
- docker.io/jenkins/jenkins:2.332.2-jdk11
- docker.io/kiwigrid/k8s-sidecar:1.15.0
<!-- Addons Package List End -->

## 공통 준비작업

```ShellSession
git clone https://github.com/playcecloud/playcekube.git
cd playcekube
cd kube-packages/jenkins
```

## 설치

### jenkins install shell

persistent 설정을 false 로 하고 사설 인증서 사용

```ShellSession
# install
/playcecloud/playcekube/kube-packages/jenkins/install-helm-charts.sh
```

또는 values.yaml 파일을 설정에 맞게 수정한 후 아래의 커맨드로 설치

```ShellSession
# copy installed-values.yaml
cp -rp /playcecloud/playcekube/kube-packages/jenkins/values.yaml /playcecloud/playcekube/kube-packages/jenkins/installed-values.yaml

# installed-values.yaml 파일을 수정

# create namespace
kubectl create ns jenkins

# jenkins install
helm install jenkins playcekube/jenkins -n jenkins -f /playcecloud/playcekube/kube-packages/jenkins/installed-values.yaml
```

