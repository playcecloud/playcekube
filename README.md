# ![PlayceKube](/assets/images/bi_PlayceKube.png)  

# PlayceKube 설치

설정과 실행 스크립트가 있는 PlayceKube.{version}.tar  파일과
repositories 데이터와 container image 데이터가 들어 있는 PlayceKubeData.{version}.tar
두개의 파일이 제공 되며 인스톨 스크립트를 실행하면 필요한 서비스들이 기동된다

```ShellSession
mkdir -p /playcecloud
# copy PlayceKube*.tar to /playcecloud
cd /playcecloud
# untar
tar xf PlayceKube.{version}.tar
cd PlayceKube
# playcekube.conf 파일 내용 확인 후 수정
# deployer config env
PLAYCE_DIR=/playcecloud
PLAYCE_DATADIR=${PLAYCE_DIR}/data
PLAYCE_DOMAIN=playcekube.local
PLAYCE_DEPLOYER=$(ip -4 -o a | grep -v "1: lo" | head -n 1 | awk '{ print $4 }' | sed 's/\(.*\)\/.*/\1/')
UPSTREAM_DNS=8.8.8.8
PLAYCEKUBE_VERSION=kv1.22.5

# install script
./playcekube_install.sh
```

# PlayceKube 지원
오픈소스컨설팅 PlayceKube팀


