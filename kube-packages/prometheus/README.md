# prometheus 설치

private helm repo 에 있는 chart 를 이용하여 설치

## 패키지 정보

<!-- Addons Package List Start -->
- kube-prometheus-stack 0.55.0
- docker.io/bats/bats:v1.4.1
- docker.io/grafana/grafana:8.4.5
- k8s.gcr.io/ingress-nginx/kube-webhook-certgen:v1.1.1
- k8s.gcr.io/kube-state-metrics/kube-state-metrics:v2.4.1
- quay.io/kiwigrid/k8s-sidecar:1.15.6
- quay.io/prometheus-operator/prometheus-config-reloader:v0.55.0
- quay.io/prometheus-operator/prometheus-operator:v0.55.0
- quay.io/prometheus/alertmanager:v0.24.0
- quay.io/prometheus/node-exporter:v1.3.1
- quay.io/prometheus/prometheus:v2.34.0
<!-- Addons Package List End -->

## 공통 준비작업

```ShellSession
git clone https://github.com/playcecloud/playcekube.git
cd playcekube
cd kube-packages/prometheus
```

## 설치

### prometheus install shell

persistent 설정을 false 로 하고 사설 인증서 사용

```ShellSession
# install
/playcecloud/playcekube/kube-packages/prometheus/install-helm-charts.sh
```

또는 values.yaml 파일을 설정에 맞게 수정한 후 아래의 커맨드로 설치

```ShellSession
# copy installed-values.yaml
cp -rp /playcecloud/playcekube/kube-packages/prometheus/values.yaml /playcecloud/playcekube/kube-packages/prometheus/installed-values.yaml

# installed-values.yaml 파일을 수정

# create namespace
kubectl create ns prometheus

# prometheus install
helm install prometheus playcekube/prometheus -n prometheus -f /playcecloud/playcekube/kube-packages/prometheus/installed-values.yaml
```

## 설치 확인

dns 서버를 deploy 서버를 지정하거나 hosts 파일에 ingress 서버 주소를 바라보도록 설정하여  
웹브라우저에서 확인  
  
이후 https://prometheus.playcek8s.playcekube.local 와 https://grafana.playcek8s.playcekube.local 로 접속하시면 확인 가능

