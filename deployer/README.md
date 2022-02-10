# ![PlayceKube](/assets/images/bi_PlayceKube.png)
# Deployer Server Config & Install

PlayceKube Deployer 서버 설정 및 설치 방법

## 설치환경 정보
Testing 환경

- OS : Rocky Linuex 8.5
- MEMORY : 16GiB
- CPU : 8core
- DISK : 200GiB
- 기본설치 PATH : /playcecloud

## 권장 모듈
Testing 환경

- docker ce 20.10.11
- git version 2.27.0

## 설치전 확인 사항
path 설정 및 git download

```ShellSession
mkdir /playcecloud
cd /playcecloud
git clone https://github.com/playcecloud/playcekube.git
cd PlayceKube/deployer
```

## 설치
### chrony,dns,registry,repositories 설정

playcekube.conf 파일에 환경 설정에 맞춰 입력

```ShellSession
# playcekube.conf
# deployer config env
PLAYCE_DIR=/playcecloud
PLAYCE_DOMAIN=playcekube.local
PLAYCE_DEPLOYER=192.168.50.10
UPSTREAM_DNS=8.8.8.8
```

설정값 입력 후 서비스 시작 shell run  
chrony 서비스는 package로 설치된다. (rocky 8.5에서 기본적으로 설치되어 있고 적당한 container가 없어 package 사용)  
container 사용을 위해 docker 을 설치 별도의 runtime은 설치 하지 않음 (이 패키지의 private 경우는 추후 고려)

```ShellSession
/playcecloud/playcekube/deployer/scripts/playcekube_service_config.sh
```

### dns,registry,repositories 서비스 시작

설정된 값으로 container 로 시작된다.

```ShellSession
/playcecloud/playcekube/deployer/scripts/playcekube_service_start.sh
```

### repo & container image download

여러 repo 파일들을 다운로드 받고 관련 container image 다운로드 후 사설 registry 로 업로드  
현재는 docker repo와 cri-o repo

```ShellSession
/playcecloud/playcekube/deployer/scripts/playcekube_repo_image_download.sh
```

### kubespray files & container image download

kubespray 로 kubernetes 설치시 필요한 files 와 container image 다운로드 후 사설 registry 로 업로드  
현재 containerd를 repo로 받지 않고 따로 다운로드 받는데 이부분에 대한 버그가 있어 fix   
또한 offline.yml 에 없는 부분이 있어 추가(containerd,runc)  
helm chrats init 부분 추가

```ShellSession
/playcecloud/playcekube/deployer/scripts/playcekube_kubespray_repo_registry_download.sh
```

### kubernetes install

kubespray.env 필요한 환경변수를 넣고 실행하면 container로 kubespray 를 실행하여 kubernetes 설치

```ShellSession
/playcecloud/playcekube/deployer/scripts/playcekube_kubespray.sh
```

설치 진행 사항 및 완료는 로그로 확인 가능

```ShellSession
docker ps  
docker logs -f {playce-kubespray:kv1.22.3로 실행된 container}

# or

tail -f /playcecloud/playcekube/deployer/kubespray/inventory/{CLUSTER_NAME}/playce-kubespray.log
```

### kubernetes cluster add

kubernetes 설치 후 kubespray.env 정보를 바탕으로 kubectl 에서 사용할 cluster 정보를 추가

```ShellSession
/playcecloud/playcekube/deployer/scripts/playcekube_kubernetes_addcluster.sh
```

## 추후

부분적으로 스크립트가 나뉘어져 있지만 후에 설치 및 이 스크립트들을 관리할 스크립트 추가 예정  
data 가 들어가는 부분을 git 하위디렉토리에서 빼는걸 고려중

# 하위 문서

- [인증서관리](certification)
- [name server](bind9)
- [repositoy](nginx)
- [registry](registry)
- [kubespray](kubespray)
- [실행 scripts](scripts)


