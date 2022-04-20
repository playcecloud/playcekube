# tekton

빌드 배포에서 ci 부분을 담당하는 시스템  
자체적으로 cd 부분까지 처리 할 수도 있고 argocd 등과 연동도 가능하다

## 패키지 정보

<!-- Addons Package List Start -->
- tekton-pipeline v0.32.1
- docker.io/alpine/git:v2.32.0
- docker.io/library/busybox:1.35.0
- docker.io/library/docker:dind
- docker.io/library/docker:latest
- docker.io/library/nginx:latest
- docker.io/library/openjdk:18-ea-34-jdk
- gcr.io/distroless/base:debug
- gcr.io/distroless/base@sha256:cfdc553400d41b47fd231b028403469811fcdbc0e69d66ea8030c5a0b5fbac2b
- gcr.io/google.com/cloudsdktool/cloud-sdk
- gcr.io/google.com/cloudsdktool/cloud-sdk:302.0.0-slim
- gcr.io/tekton-releases/github.com/tektoncd/dashboard/cmd/dashboard:v0.25.0
- gcr.io/tekton-releases/github.com/tektoncd/pipeline/cmd/controller:v0.32.1
- gcr.io/tekton-releases/github.com/tektoncd/pipeline/cmd/entrypoint:v0.32.1
- gcr.io/tekton-releases/github.com/tektoncd/pipeline/cmd/git-init:v0.32.1
- gcr.io/tekton-releases/github.com/tektoncd/pipeline/cmd/imagedigestexporter:v0.32.1
- gcr.io/tekton-releases/github.com/tektoncd/pipeline/cmd/kubeconfigwriter:v0.32.1
- gcr.io/tekton-releases/github.com/tektoncd/pipeline/cmd/nop:v0.32.1
- gcr.io/tekton-releases/github.com/tektoncd/pipeline/cmd/pullrequest-init:v0.32.1
- gcr.io/tekton-releases/github.com/tektoncd/pipeline/cmd/webhook:v0.32.1
<!-- Addons Package List End -->

## 공통 준비작업

```ShellSession
git clone https://github.com/playcecloud/playcekube.git
cd playcekube
cd kube-packages/tekton
```

## 설치

### tekton install shell

사설 인증서 사용하여 dashboard 구성  
tekton 리소스 생성 및 사용은 주로 cli를 사용

```ShellSession
# install
/playcecloud/playcekube/kube-packages/tekton/install-helm-charts.sh
```

또는 values.yaml 파일을 설정에 맞게 수정한 후 아래의 커맨드로 설치

```ShellSession
# copy installed-values.yaml
cp -rp /playcecloud/playcekube/kube-packages/tekton/values.yaml /playcecloud/playcekube/kube-packages/tekton/installed-values.yaml

# installed-values.yaml 파일을 수정

# create namespace
kubectl create ns tekton

# tekton install
helm install tekton playcekube/tekton -n tekton -f /playcecloud/playcekube/kube-packages/tekton/installed-values.yaml
```

## 설치 확인

dns 서버를 deploy 서버를 지정하거나 hosts 파일에 ingress 서버 주소를 바라보도록 설정하여  
웹브라우저에서 확인  
  
이후 https://tekton.playcek8s.playcekube.local 로 접속하시면 확인 가능

### tekton cli command tool

tkn 이란 cli 툴이 다운받아져 있으며 설치 후 사용 가능
다음은 로그 보는 예제

```ShellSession
# piplinerun-test 이란 이름의 pipelinerun 실행 과정 로그를 본다
tkn pipelinerun logs -f piplinerun-test
```

## Usage & Example

- [Usage](usage)
- [maven example](usage/maven-example)
- [python example](usage/python-example)
- [simple example](usage/simple-example)

