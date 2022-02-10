# argocd 설치

https://argoproj.github.io/argo-helm argo-cd helm chart를 사설 chart repo 에 저장  
기본값으로 설치 할 수 있는 install shell 도 만들어 둔다

## 공통 준비작업

```ShellSession
git clone -b dev https://github.com/OpenSourceConsulting/PlayceKube.git
cd PlayceKube
cd kube-packages/argo
```

## 설치

### argo chart private install

```ShellSession
# helm chart add private chart
/playcecloud/playcekube/kube-packages/argo/add-helm-charts.sh
```

### argo install shell

```ShellSession
# install
/playcecloud/playcekube/kube-packages/argo/install-helm-charts.sh
```

## 설치 확인

