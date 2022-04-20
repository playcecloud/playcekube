# gitlab 설치

private helm repo 에 있는 chart 를 이용하여 설치

## 패키지 정보

<!-- Addons Package List Start -->
- gitlab 14.9.3
- docker.io/bitnami/postgres-exporter:0.8.0-debian-10-r99
- docker.io/bitnami/postgresql:12.7.0
- docker.io/bitnami/redis-exporter:1.12.1-debian-10-r11
- docker.io/bitnami/redis:6.0.9-debian-10-r0
- docker.io/gitlab/gitlab-runner:alpine-v14.9.0
- docker.io/jimmidyson/configmap-reload:v0.5.0
- docker.io/minio/mc:RELEASE.2018-07-13T00-53-22Z
- docker.io/minio/minio:RELEASE.2017-12-28T01-21-00Z
- quay.io/jetstack/cert-manager-cainjector:v1.5.4
- quay.io/jetstack/cert-manager-controller:v1.5.4
- quay.io/jetstack/cert-manager-ctl:v1.5.4
- quay.io/jetstack/cert-manager-webhook:v1.5.4
- quay.io/prometheus/prometheus:v2.31.1
- registry.gitlab.com/gitlab-org/build/cng/alpine-certificates:20191127-r2@sha256:4678ac2a66f126b20362faddd333be907d4eded47a7fb8ea2653c1522ddbed49
- registry.gitlab.com/gitlab-org/build/cng/gitaly:v14.9.3
- registry.gitlab.com/gitlab-org/build/cng/gitlab-container-registry:v3.32.0-gitlab
- registry.gitlab.com/gitlab-org/build/cng/gitlab-exporter:11.12.0
- registry.gitlab.com/gitlab-org/build/cng/gitlab-shell:v13.24.0
- registry.gitlab.com/gitlab-org/build/cng/gitlab-sidekiq-ce:v14.9.3
- registry.gitlab.com/gitlab-org/build/cng/gitlab-toolbox-ce:v14.9.3
- registry.gitlab.com/gitlab-org/build/cng/gitlab-toolbox-ce:v14.9.3
- registry.gitlab.com/gitlab-org/build/cng/gitlab-webservice-ce:v14.9.3
- registry.gitlab.com/gitlab-org/build/cng/gitlab-webservice-ce:v14.9.3
- registry.gitlab.com/gitlab-org/build/cng/gitlab-workhorse-ce:v14.9.3
- registry.gitlab.com/gitlab-org/build/cng/kubectl:1.18.20@sha256:824750f20381facb70cb90d3cd41da075d7ffde5a14de6f14f7037285fe0ddb7
- registry.gitlab.com/gitlab-org/build/cng/kubectl:1.18.20@sha256:824750f20381facb70cb90d3cd41da075d7ffde5a14de6f14f7037285fe0ddb7
- registry.gitlab.com/gitlab-org/cloud-native/mirror/images/busybox:latest
- registry.gitlab.com/gitlab-org/cloud-native/mirror/images/busybox:latest
- registry.gitlab.com/gitlab-org/cloud-native/mirror/images/defaultbackend-amd64:1.5@sha256:4dc5e07c8ca4e23bddb3153737d7b8c556e5fb2f29c4558b7cd6e6df99c512c7
- registry.gitlab.com/gitlab-org/cloud-native/mirror/images/ingress-nginx/controller:v1.0.4@sha256:545cff00370f28363dad31e3b59a94ba377854d3a11f18988f5f9e56841ef9ef
<!-- Addons Package List End -->

## 공통 준비작업

```ShellSession
git clone https://github.com/playcecloud/playcekube.git
cd playcekube
cd kube-packages/gitlab
```

## 설치

### gitlab install shell

persistent 설정을 false 로 하고 사설 인증서 사용

```ShellSession
# install
/playcecloud/playcekube/kube-packages/gitlab/install-helm-charts.sh
```

또는 values.yaml 파일을 설정에 맞게 수정한 후 아래의 커맨드로 설치

```ShellSession
# copy installed-values.yaml
cp -rp /playcecloud/playcekube/kube-packages/gitlab/values.yaml /playcecloud/playcekube/kube-packages/gitlab/installed-values.yaml

# installed-values.yaml 파일을 수정

# create namespace
kubectl create ns gitlab

# gitlab install
helm install gitlab playcekube/gitlab -n gitlab -f /playcecloud/playcekube/kube-packages/gitlab/installed-values.yaml
```

## 설치 확인

dns 서버를 deploy 서버를 지정하거나 hosts 파일에 ingress 서버 주소를 바라보도록 설정하여  
웹브라우저에서 확인  
  
이후 https://gitlab.playcek8s.playcekube.local 로 접속하시면 확인 가능

