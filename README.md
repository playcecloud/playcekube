이 매뉴얼은 베어메탈 환경에서 Kubernetes를 기본으로 한 Playce Kube을 설치할 수 있는 사용자 가이드입니다.
PlayceKube 는 테스트 환경에서 컨테이너를 배포하기 위해 구축된 오픈소스 컨테이너 관리 플랫폼이며, 본 솔루션을 사용하면 다양한 컴퓨팅 환경에서 Kubernetes를 보다 쉽게 설치하고 실행 할 수 있습니다. 

Playce Kube를 설치하는 **기본 환경은 Deploy Node 1대, Master Node 1대, Worker Node 1대를 기준으로 설치**를 진행합니다.

# Playce Kube 설치
### 최소/권장 요구 조건(Single Host 사양)

| 항목   | 권장사양        | 최소사양        |
| :----- | :-------------- | :-------------- |
| CPU    | 8 Core          | 8 Core          |
| Memory | 16 GB           | 4 GB            |
| HDD    | 200 GB >        | 200 GB          |
| OS     | Rocky Linux 8.5 | Rocky Linux 8.5 |

위 사양 수준의 3대가 기본적으로 구성되어야 하며, Rocky Linux 8.5를 해당 서버의 OS로 설치, 구성되도록 합니다.


### 필수 소프트웨어 항목
디플로이 노드는 Playce Kube를 설치하기 위한 다양한 라이브러리, 환경 설정 파일 등을 관리하는 목적을 가지면 필수로 설치되어야 하는 항목입니다. 이를 Deploy Node로 명명하며 필요한 소프트웨어 버전은 다음과 같습니다.
- **Deploy Node** : git version 2.27 or later


### 사전설치준비

Playce Kube를 설치하려면 먼저 호스트 머신에서 몇 가지 기본 설정을 완료 해야 합니다. 몇 가지 간단한 절차를 진행해야 하며, 아래의 순서에 따라 반영되도록 합니다.


**절차**

1. Playce Kube 설치를 위한 모든 호스트(deploy,master,worker)에서 아래 패키지를 삭제 합니다.
   ```shell
   $ dnf remove podman
   $ dnf remove containers-common
   ```

2. `root`사용자로 모든 호스트에 로그인 합니다.

3. 모든 호스트 이름을 확인합니다.

   ```shell
   $ hostname
   $ hostname -f
   ```

   해당 명령에서 올바른 정규화된(FQDN0) 호스트 이름이 출력되지 않거나 오류가 나타나는 경우 `hostnamectl`을 사용하여 호스트 이름을 설정합니다. 

   ```shell
   $ hostnamectl set-hostname playcekube-deploy.example.com
   ```


4. 각 노드들의 통신을 위하여 모든 호스트의 기본 방화벽을 해제 합니다.

   ```shell
   $ Vi /etc/selinux/config
   SELINUX=disabled
   ```

5. (선택 사항) 모든 호스트 시스템을 최신 패키지로 유지 하고 싶은 경우 진행합니다.

   ```shell
   $ dnf update -y
   $ reboot
   ```


6. 사전 설정이 완료 되었으면 각 호스트를 재부팅 합니다.

   ```shell
   $ reboot
   ```



## Deploy Node 설치 및 구성

**절차**

1. deploy 템플릿용 디렉터리를 생성하고 해당 디렉토리로 이동합니다.

   ```shell
   $ mkdir /playcecloud
   $ cd /playcecloud
   ```

2. Playce Kube용 프로젝트를 아래의 사이트에서 clone 합니다.

   ```shell
   $ git clone https://github.com/playcecloud/playcekube.git
   ```

   만약 git 명령 수행에 오류가 나거나 관련 패키지가 없을 경우에는 git 패키지를 설치 합니다.

   ```shell
   $ dnf install git -y
   ```

   

3. playcekube data 파일 다운로드를 위한 디렉토리를 생성하고 해당 디렉토리로 이동합니다. 

   - 다운로드 폴더 생성 및 이동
     ```shell
     $ mkdir -p /playcecloud/downloadsrc
     $ cd /playcecloud/downloadsrc
     ```

     

   - Playce Kube Data 파일 다운로드

     ```shell
     $ curl -LO http://download.playcecloud.io:13300/playcekube/PlayceKubeData.K8SRepo.v1.22-1.0.tar
     $ curl -LO http://download.playcecloud.io:13300/playcekube/PlayceKubeData.OSRepo.v1.22-1.0.tar
     $ curl -LO http://download.playcecloud.io:13300/playcekube/PlayceKubeData.Registry.v1.22-1.0.tar
     ```

     

4. **playce.conf**  파일을 정의 합니다.

   `playce.conf`파일은 deploy 설치시 하위 매개 변수를 기반으로 설치됩니다.

   ```shell
   $ cd /playcecloud/playceKube
   ```

   **설정 파라미터** 

   ```shell
   # deployer config env
   PLAYCE_DIR=/playcecloud          	# PlayceCloud 설치 경로
   PLAYCE_DATADIR=${PLAYCE_DIR}/data   # PlayceCloud data 경로
   PLAYCE_DOMAIN=playcekube.local      # PlayceCloud domain 이름
   PLAYCE_DEPLOYER=10.10.10.1       	# PlayceCloud deploy node IP Address
   UPSTREAM_DNS=8.8.8.8          		# DNS
   PLAYCEKUBE_VERSION=v1.22-1.0        # PlayceKube Version
   ```

5. deploy 설치를 진행합니다.

   ```shell
   $ /playcecloud/playcekube/playcekube_install.sh 
   ```

   

6. 설치 deploy 버전 확인합니다.

   ```shell
   $ cat /playcecloud/playcekube/release.txt
   ```

   

## 클러스터 설치 및 구성

기본적인 PlayceKube 설치는 끝났으며, 해당 섹션에서는 PlayceKube를 이용하여 클러스터 설치 및 구성 하는 과정을 보여줍니다. 
Playce Kube 클러스터는 kubernetes kubespray 를 이용하여 설치가 제공되며,  `kubespray.env`파일을 기본으로 환경 구성을 한 후  `playcekube_kubespray.sh`를 실행하여 배포 합니다. 

Kubespray에 대한 자세한 설명은 [여기](https://kubespray.io/#/) 를 참조 하면 됩니다.


**절차**

1. kubespray sample 파일을 작업 경로로 복사 합니다.
   ```shell
   $ cp /playcecloud/playcekube/deployer/kubespray/kubespray-sample.env /playcecloud/playcekube/kubespray.env
   ```

2. `kubespray.env` 파일을 정의합니다.

   ```shell
   # playcekube_kubespray
   # env file
   
   #MODE [DEPLOY, UPGRADE, RESET, SCALE, REMOVE-NODE, JUST-INVENTORY]
   MODE=DEPLOY
   CREATE_INVENTORY=true
   FORCE_CREATE_INVENTORY=true
   
   # cluster name, inventory name
   CLUSTER_NAME=playcek8s
   
   # workernode & masternode password
   NODE_PASSWD=oscadmin
   
   PRIVATE_DNS=10.10.40.1
   PRIVATE_REPO=repositories.playcekube.local
   PRIVATE_REGISTRY=registry.playcekube.local:5000
   PRIVATE_NTP=10.10.40.1
   
   MASTERS=playcekube-master01:10.10.40.150
   WORKERS=playcekube-worker01:10.10.40.151,playcekube-worker02:10.10.40.152
   INGRESSES=playcekube-master01
   ```
   

   각각의 설정에서 하위 파라미터 세트를 통해 사용 방법을 정의할 수 있습니다. 
   다음 표에는 하위 파라미터에 대한 정보가 나와 있습니다.


   | 설정 파라미터          | 설명                                                         |
   | ---------------------- | ------------------------------------------------------------ |
   | MODE                   | DEPLOY, UPGRADE, RESET, SCALE, REMOVE-NODE, JUST-INVENTORY   |
   | CREATE_INVENTORY       | 인벤토리 파일을 생성할지 여부                                |
   | FORCE_CREATE_INVENTORY | 클러스터 이름 기준으로 inventory 가 생성되는데 같은 클러스터 이름이 있을 경우 지우고 새로 만들 것인지 에 대한 여부 |
   | CLUSTER_NAME           | 클러스터 이름,inventory 이름                                 |
   | NODE_PASSWD            | 마스터 및 워커 노드의 SSH 접근을 위한 패스워드 정보          |
   | CLUSTER_RUNTIME        | 클러스터 런타임 종류(containerd, docker, crio)               |
   | SERVICE_NETWORK        | 서비스 네트워크                                              |
   | POD_NETWORK            | 파드 네트워크                                                |
   | PRIVATE_DNS            | 사설 dns 서버 주소<br /> > 일반적으로 deploy 노드 IP         |
   | PRIVATE_REPO           | 사설 repository 서버<br /> > 도메인 기반으로 설정되어 있으며 일반적으로 deploy 노드 IP |
   | PRIVATE_REGISTRY       | 사설 registry 서버 IP<br /> > 도메인 기반으로 설정되어 있으며 일반적으로 deploy 노드 IP |
   | PRIVATE_NTP            | 사설 NTP 서비스를 제공할 IP 정보                             |
   | MASTERS                | 마스터 노드의 SSH 접근을 위한 IP 정보                        |
   | WORKERS                | 워커 노드의 SSH 접근을 위한 IP 정보                          |
   | INGRESSES              | 인그레스 설치할 노드 정보                                   |

   

3.  클러스터를 설치합니다. 

   **-e** 옵션으로도 개별 환경 설정을 넣을 수 있습니다

   ```shell
   $ cd /playcecloud/PlayceKube/
   $ /playcecloud/PlayceKube/deployer/scripts/playcekube_kubespray.sh -f kubespray.env
   ```



## 문제 해결(FAQ)

문제 발생시 [여기](https://github.com/playcecloud/playcekube/issues) 를 통해 문의 해 주세요



## Release 정보

### Release 노트

현재 PlayceKube 버전은 v1.22-1.0 이며 해당 릴리즈는 Kubernetes v1.22.x 를 사용합니다.
이 항목에는 PlayceKube v1.22-1.0 에 관한 새로운 기능, 변경 사항 및 알려진 문제가 포함되어 있습니다.


이전 릴리즈 정보를 확인은 [이전 릴리즈 정보 ]() 에서 할 수 있습니다.


### Release 정보

| 구분       | 제품버전 | 최종 릴리즈 |
| ---------- | -------- | ----------- |
| PlayceKube | v1.22-1.0| 2022-04-20  |

Copyright © 2022 Playce Cloud/Playce Kube ®. All rights reserved. Open Source Consulting, Inc has registered trademarks and uses trademarks. 

