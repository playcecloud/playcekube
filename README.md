# ![PlayceKube](/assets/images/bi_PlayceKube.png)  

# PlayceKube 설치

git 에서 clone 으로 설정과 실행 스크립트를 다운로드  
repositories 데이터와 container image 데이터가 들어 있는 PlayceKubeData.{type}.{version}.tar
세개의 파일을 curl 이나 wget 등으로 다운로드 후 인스톨 스크립트 실행

```ShellSession
mkdir -p /playcecloud
cd /playcecloud

# clone playcekube git
git clone https://github.com/playcecloud/playcekube.git

cd /playcecloud/playcekube

# playcekube.conf 파일 내용 확인 후 수정
# deployer config env
PLAYCE_DIR=/playcecloud
PLAYCE_DATADIR=${PLAYCE_DIR}/data
PLAYCE_DOMAIN=playcekube.local
PLAYCE_DEPLOYER=$(ip -4 -o a | grep -v "1: lo" | head -n 1 | awk '{ print $4 }' | sed 's/\(.*\)\/.*/\1/')
UPSTREAM_DNS=8.8.8.8
PLAYCEKUBE_VERSION=kv1.22.5

# download data file
mkdir -p /playcecloud/downloadsrc
cd /playcecloud/downloadsrc
curl -LO http://download.playcecloud.io:13300/playcekube/PlayceKubeData.K8SRepo.{version}.tar
curl -LO http://download.playcecloud.io:13300/playcekube/PlayceKubeData.OSRepo.{version}.tar
curl -LO http://download.playcecloud.io:13300/playcekube/PlayceKubeData.Registry.{version}.tar

# install script
cd /playcecloud/playcekube
./playcekube_install.sh
```

# PlayceKube 지원
오픈소스컨설팅 PlayceKube팀


