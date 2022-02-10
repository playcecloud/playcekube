# minio 설치

private helm repo 에 있는 chart 를 이용하여 설치

## 공통 준비작업

```ShellSession
git clone -b dev https://github.com/OpenSourceConsulting/PlayceKube.git
cd PlayceKube
cd kube-packages/minio
```

## 설치

### minio install shell

persistent 설정을 false 로 하고 사용

```ShellSession
# install
/playcecloud/playcekube/kube-packages/minio/install-helm-charts.sh
```

또는 values.yaml 파일을 설정에 맞게 수정한 후 아래의 커맨드로 설치

```ShellSession
# copy installed-values.yaml
cp -rp /playcecloud/playcekube/kube-packages/minio/values.yaml /playcecloud/playcekube/kube-packages/minio/installed-values.yaml

# installed-values.yaml 파일을 수정

# create namespace
kubectl create ns minio

# minio install
helm install minio playcekube/minio -n minio -f /playcecloud/playcekube/kube-packages/minio/installed-values.yaml
```

## 설치 확인

사내망 에서 Windows 사용시 C:\Windows\System32\drivers\etc\hosts 파일에 다음과 같은 설정을 추가하면 브라우저로 접속이 가능(ip는 설정에 따라 다름. 본인은 중간에 haproxy로 deployer 서버를 바라보게 해서 설정)  
192.168.50.100 repositories.playcekube.local  
192.168.50.100 minio.playcek8s.playcekube.local  
  
다음과 같은 url로 인증서를 Windows에서 신뢰된 루트 인증서로 등록을 하면 테스트가 더 수월합니다  
http://repositories.playcekube.local/certs/playcekube_rootca.crt  

이후 https://minio.playcek8s.playcekube.local 로 접속하시면 확인 가능

