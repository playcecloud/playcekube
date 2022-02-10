# registry

PlayceKube Deployer 서버에서 사용할 image registry 서버

## 설치환경 정보
Testing 환경

- OS : Rocky Linuex 8.5
- MEMORY : 16GiB
- CPU : 8core
- DISK : 200GiB
- 기본설치 PATH : /playcecloud

## 사용 모듈

- docker ce 20.10.11
- docker.io/library/registry:2.7.1

## registry 정보

이 디렉토리는 registry 설정 정보가 있고 실행 쉘은 따로 있다  
container registry server 를 사용하고 있으며 ssl 설정도 되어 있음
(insecure 설정을 안해도 되는 장점이 있음)

### 설정 정보

config.yml설정 파일들이 registry container에 매핑되어 있으며 registry data는 별도의 디렉토리로 연결
inventory 디렉토리는 container 의 inventory 디렉토리와 매핑
run_kubespray.sh 는 container 에 포함되는 쉘
kubespray_ssh* 는 배포할때 사용할 ssh 키쌍


### 서비스 실행

서비스 실행은 별도의 스크립트 파일을 제공하며 다음 실행 명령은 참고로 적어둠  
설정 파일,ssl 파일 및 registry data 디렉토리 매핑
ssl 설정을 하여 port 5000 https 로 접근 (insecure 설정 불필요)

```ShellSession
# registry container restart
docker stop playcekube_registry
docker rm playcekube_registry
docker run -d --name playcekube_registry \
--restart always \
-v /playcecloud/playcekube/deployer/registry:/etc/docker/registry \
-v /playcecloud/data/registry:/var/lib/registry \
-p 5000:5000 \
docker.io/library/registry:2.7.1
```

