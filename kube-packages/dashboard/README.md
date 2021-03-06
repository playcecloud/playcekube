# kubernetes-dashboard 설치

private helm repo 에 있는 chart 를 이용하여 설치

## 패키지 정보

<!-- Addons Package List Start -->
- kubernetes-dashboard 2.5.1
- docker.io/kubernetesui/dashboard:v2.5.1
- docker.io/kubernetesui/metrics-scraper:v1.0.7
<!-- Addons Package List End -->

## 공통 준비작업

```ShellSession
git clone https://github.com/playcecloud/playcekube.git
cd playcekube
cd kube-packages/dashboard
```

## 설치

### kubernetes-dashboard install shell

persistent 설정을 false 로 하고 사용

```ShellSession
# install
/playcecloud/playcekube/kube-packages/dashboard/install-helm-charts.sh
```

또는 values.yaml 파일을 설정에 맞게 수정한 후 아래의 커맨드로 설치

```ShellSession
# copy installed-values.yaml
cp -rp /playcecloud/playcekube/kube-packages/dashboard/values.yaml /playcecloud/playcekube/kube-packages/dashboard/installed-values.yaml

# installed-values.yaml 파일을 수정

# create namespace
kubectl create ns kubernetes-dashboard

# kubernetes-dashboard install
helm install kubernetes-dashboard playcekube/kubernetes-dashboard -n kubernetes-dashboard -f /playcecloud/playcekube/kube-packages/dashboard/installed-values.yaml
```

### 접속 계정 생성

kubernetes의 service account 를 생성하고 접속 토큰 정보를 얻는 방법  
다음은 클러스터 관리자 권한을 갖는 service account 를 생성 하고 해당 접속 토큰을 얻는 방법의 예제이다

```ShellSession
# create serice account (dashboard-admin)
kubectl create serviceaccount dashboard-admin -n default
# create cluster role binding (cluster admin)
kubectl create clusterrolebinding --clusterrole=cluster-admin --serviceaccount=default:dashboard-admin dashboard-admin

# get token
SECRET_NAME=$(kubectl get serviceaccounts dashboard-admin -n default -o jsonpath='{.secrets[0].name}')
SECRET_TOKEN=$(kubectl get secrets ${SECRET_NAME} -n default -o jsonpath='{.data.token}' | base64 --decode)
echo ${SECRET_TOKEN}
```

## 설치 확인

dns 서버를 deploy 서버를 지정하거나 hosts 파일에 ingress 서버 주소를 바라보도록 설정하여  
웹브라우저에서 확인
  
이후 https://dashboard.playcek8s.playcekube.local 로 접속하시면 확인 가능

