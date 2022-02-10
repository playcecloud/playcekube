# bind9

PlayceKube Deployer 서버에서 사용할 dns 서버

## 설치환경 정보
Testing 환경

- OS : Rocky Linuex 8.5
- MEMORY : 16GiB
- CPU : 8core
- DISK : 200GiB
- 기본설치 PATH : /playcecloud

## 사용 모듈

- docker ce 20.10.11
- docker.io/ubuntu/bind9:9.16-21.10_edge

## bind9 정보

이 디렉토리는 bind9 설정 정보가 있고 실행 쉘은 따로 있습니다  
실행은 container로 실행되며 관련정보는 아래에 기술합니다

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
타임존 설정은 서울  
각 디렉토리 매핑은 상단의 설정정보에 있음  
container 에 들어가는 named.conf 에서는 port 오픈을 8053으로 하여 외부 53으로 연결 (container 실행 유저가 bind로 되어 있어 53포트를 열지 못하여 기동이 되지 않아 이렇게 설정)

```ShellSession
# dns(bind9) container restart
docker stop playcekube_bind9
docker rm playcekube_bind9
docker run -d --name playcekube_bind9 \
--restart always \
-e TZ=Asia/Seoul \
-v /playcecloud/playcekube/deployer/bind9/config/named.conf:/etc/bind/named.conf \
-v /playcecloud/playcekube/deployer/bind9/cache:/var/cache/bind \
-v /playcecloud/playcekube/deployer/bind9/records:/run/name \
-p 53:8053/udp \
-p 53:8053 \
docker.io/ubuntu/bind9:9.16-21.10_edge
```

