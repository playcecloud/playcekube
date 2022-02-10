# Deployer Manage Scripts

PlayceKube Deployer 서버 설정 및 설치 Scripts

## 설치환경 정보
Testing 환경

- OS : Rocky Linuex 8.5
- MEMORY : 16GiB
- CPU : 8core
- DISK : 200GiB
- 기본설치 PATH : /playcecloud

## 사용 모듈
Testing 환경

- docker version 3.3.1
- git version 2.27.0
- GNU bash, version 4.4.20(1)-release
- chrony-4.1-1
- docker.io/library/nginx:1.20.2
- docker.io/library/registry:2.7.1
- docker.io/ubuntu/bind9:9.16-21.10_edge

## 설치전 확인 사항
path 설정 및 git download

```ShellSession
mkdir /playcecloud
cd /playcecloud
git clone https://github.com/playcecloud/playcekube.git
cd playcekube/deployer/scripts
```

## Scripts 설명

* 서비스 설치 설정 및 기동 (ntp, repository, registry, docker)  
1. playcekube_service_config.sh 로 기본 서비스 설정 디렉토리 및 설정파일을 만든다  
2. playcekube_service_start.sh 로 기본 서비스를 시작한다 (기존 기동된 것이 있으면 삭제 후 다시 기동)  

* 클러스터 배포  
1. playcekube_kubespray.sh 는 kubespray env 설정값 기반으로 배포,리셋,스케일 아웃,스케일 인등의 작업을 한다
2. playcekube_kubernetes_addcluster.sh 는 kubespray env 설정값 기반으로 deployer 서버에 kubeconfig 를 등록한다
(1번 스크립트에서 자동으로 2번까지 동작함)

```ShellSession
/playcecloud/playcekube/deployer/scripts/playcekube_kubespray.sh -f /playcecloud/playcekube/deployer/kubespray-sample.env
```

