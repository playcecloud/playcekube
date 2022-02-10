# repository

PlayceKube Deployer 서버에서 사용할 repository 서버

## 설치환경 정보
Testing 환경

- OS : Rocky Linuex 8.5
- MEMORY : 16GiB
- CPU : 8core
- DISK : 200GiB
- 기본설치 PATH : /playcecloud

## 사용 모듈

- docker ce 20.10.11
- docker.io/library/nginx:1.20.2

## repository 정보

이 디렉토리는 repository 설정 정보가 있고 실행 쉘은 따로 있다  
container nginx 를 사용하고 있으며 ssl 설정도 되어 있음

### 설정 정보

각 디렉토리는 ubuntu 기반의 bind9 container에 스토리지 매핑 되어 있다

```ShellSession
# 설정 파일 named.conf 가 있는 디렉토리
/playcecloud/playcekube/deployer/bind9/config
# zone 파일 경로 (ubuntu 계열에서는 기본 디렉토리가 /var/cache/bind 이다)
/playcecloud/playcekube/deployer/bind9/cache
# container 사용하는 설명에 들어가 있던데 뭐가 들어가는지는 모름..;;
/playcecloud/playcekube/deployer/bind9/records
```

### 서비스 실행

서비스 실행은 별도의 스크립트 파일을 제공하며 다음 실행 명령은 참고로 적어둠  
설정 파일 및 ssl 디렉토리르 container와 매핑  
실제 데이타가 들어갈 디렉토리도 매핑하여 로컬파일로 관리  
ssl 설정을 하여 http,https 모두 사용할 수 있도록함(ssl redirect X)

```ShellSession
# repositories(nginx) container restart
docker stop playcekube_repositories
docker rm playcekube_repositories
docker run -d --name playcekube_repositories \
--restart always \
-v /playcecloud/playcekube/deployer/nginx/repositories.conf:/etc/nginx/nginx.conf \
-v /playcecloud/playcekube/deployer/nginx/servers.conf:/etc/nginx/servers.conf \
-v /playcecloud/playcekube/deployer/nginx/ssl:/etc/nginx/ssl \
-v /playcecloud/data/repositories:/repositories \
-p 80:80 \
-p 443:443 \
docker.io/library/nginx:1.20.2
```

