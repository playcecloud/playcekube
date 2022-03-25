# ingress-nginx

서비스 매쉬

## 공통 준비작업

```ShellSession
git clone https://github.com/playcecloud/playcekube.git
cd playcekube
cd kube-packages/ingress-nginx
```

## 설치

### ingress-nginx install shell

```ShellSession
# install
/playcecloud/playcekube/kube-packages/ingress-nginx/install-helm-charts.sh
```

또는 values.yaml 파일을 설정에 맞게 수정한 후 아래의 커맨드로 설치

```ShellSession
# copy installed-values.yaml
cp -rp /playcecloud/playcekube/kube-packages/ingress-nginx/values.yaml /playcecloud/playcekube/kube-packages/ingress-nginx/installed-values.yaml

# installed-values.yaml 파일을 수정
# class2-values.yaml 파일을 수정
#controller.ingressClassResource.name
#controller.ingressClassResource.controllerValue
#controller.ingressClass
#controller.hostPort.ports.http
#controller.hostPort.ports.https

# create namespace
kubectl create ns ingress-nginx

# ingress-nginx install
helm install ingress-nginx playcekube/ingress-nginx -n ingress-nginx -f /playcecloud/playcekube/kube-packages/ingress-nginx/installed-values.yaml
# or other class
helm upgrade -i ingress-nginx2 playcekube/ingress-nginx -f class2-values.yaml -n ingress-nginx
```

