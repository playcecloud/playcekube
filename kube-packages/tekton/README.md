# tekton

빌드 배포에서 ci 부분을 담당하는 시스템  
자체적으로 cd 부분까지 처리 할 수도 있고 argocd 등과 연동도 가능하다

## 공통 준비작업

```ShellSession
git clone https://github.com/playcecloud/playcekube.git
cd PlayceKube
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

사내망 에서 Windows 사용시 C:\Windows\System32\drivers\etc\hosts 파일에 다음과 같은 설정을 추가하면 브라우저로 접속이 가능(ip는 설정에 따라 다름. 본인은 중간에 haproxy로 deployer 서버를 바라보게 해서 설정)
192.168.50.100 repositories.playcekube.local
192.168.50.100 tekton.playcek8s.playcekube.local

다음과 같은 url로 인증서를 Windows에서 신뢰된 루트 인증서로 등록을 하면 테스트가 더 수월합니다
http://repositories.playcekube.local/certs/playcekube_rootca.crt

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

