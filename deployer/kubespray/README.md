# kubespray

kubespray 설정 및 설치

## 사용 모듈 리스트

- docker ce 20.10.11
- kubespray v.2.18.0 branch custom build

<!-- Kubespray Use List Start -->

#### Kubespray File List

- https://storage.googleapis.com/kubernetes-release/release/v1.22.5/bin/linux/amd64/kubelet
- https://storage.googleapis.com/kubernetes-release/release/v1.22.5/bin/linux/amd64/kubectl
- https://storage.googleapis.com/kubernetes-release/release/v1.22.5/bin/linux/amd64/kubeadm
- https://storage.googleapis.com/gvisor/releases/release/20210921/x86_64/runsc
- https://storage.googleapis.com/gvisor/releases/release/20210921/x86_64/containerd-shim-runsc-v1
- https://github.com/projectcalico/calicoctl/releases/download/v3.20.3/calicoctl-linux-amd64
- https://github.com/projectcalico/calico/archive/v3.20.3.tar.gz
- https://github.com/opencontainers/runc/releases/download/v1.0.3/runc.amd64
- https://github.com/kubernetes-sigs/krew/releases/download/v0.4.2/krew-_amd64.tar.gz
- https://github.com/kubernetes-sigs/cri-tools/releases/download/v1.22.0/crictl-v1.22.0-linux-amd64.tar.gz
- https://github.com/kata-containers/kata-containers/releases/download/2.2.3/kata-static-2.2.3-x86_64.tar.xz
- https://github.com/flannel-io/cni-plugin/releases/download/v1.0.0/flannel-amd64
- https://github.com/coreos/etcd/releases/download/v3.5.0/etcd-v3.5.0-linux-amd64.tar.gz
- https://github.com/containers/crun/releases/download/1.3/crun-1.3-linux-amd64
- https://github.com/containernetworking/plugins/releases/download/v1.0.1/cni-plugins-linux-amd64-v1.0.1.tgz
- https://github.com/containerd/nerdctl/releases/download/v0.15.0/nerdctl-0.15.0-linux-amd64.tar.gz
- https://github.com/containerd/containerd/releases/download/v1.5.8/containerd-1.5.8-linux-amd64.tar.gz
- https://get.helm.sh/helm-v3.7.1-linux-amd64.tar.gz

#### Kubespray Container Images

- quay.io/jetstack/cert-manager-webhook:v1.5.4
- quay.io/jetstack/cert-manager-controller:v1.5.4
- quay.io/jetstack/cert-manager-cainjector:v1.5.4
- quay.io/external_storage/rbd-provisioner:v2.1.1-k8s1.11
- quay.io/external_storage/cephfs-provisioner:v2.1.0-k8s1.11
- quay.io/coreos/flannel:v0.15.1-amd64
- quay.io/coreos/etcd:v3.5.0
- quay.io/cilium/operator:v1.9.11
- quay.io/cilium/cilium:v1.9.11
- quay.io/cilium/cilium-init:2019-04-05
- quay.io/calico/typha:v3.20.3
- quay.io/calico/pod2daemon-flexvol:v3.20.3
- quay.io/calico/node:v3.20.3
- quay.io/calico/kube-controllers:v3.20.3
- quay.io/calico/cni:v3.20.3
- k8s.gcr.io/sig-storage/snapshot-controller:
- k8s.gcr.io/sig-storage/local-volume-provisioner:v2.4.0
- k8s.gcr.io/sig-storage/csi-snapshotter:v4.2.1
- k8s.gcr.io/sig-storage/csi-resizer:v1.3.0
- k8s.gcr.io/sig-storage/csi-provisioner:v3.0.0
- k8s.gcr.io/sig-storage/csi-node-driver-registrar:v2.4.0
- k8s.gcr.io/sig-storage/csi-attacher:v3.3.0
- k8s.gcr.io/pause:3.3
- k8s.gcr.io/metrics-server/metrics-server:v0.5.0
- k8s.gcr.io/kube-scheduler:v1.22.5
- k8s.gcr.io/kube-proxy:v1.22.5
- k8s.gcr.io/kube-controller-manager:v1.22.5
- k8s.gcr.io/kube-apiserver:v1.22.5
- k8s.gcr.io/ingress-nginx/controller:v1.0.4
- k8s.gcr.io/dns/k8s-dns-node-cache:1.21.1
- k8s.gcr.io/cpa/cluster-proportional-autoscaler-amd64:1.8.5
- k8s.gcr.io/coredns/coredns:v1.8.0
- k8s.gcr.io/addon-resizer:1.8.11
- ghcr.io/k8snetworkplumbingwg/multus-cni:v3.8
- docker.io/xueshanf/install-socat:latest
- docker.io/weaveworks/weave-npc:2.8.1
- docker.io/weaveworks/weave-kube:2.8.1
- docker.io/rancher/local-path-provisioner:v0.0.19
- docker.io/mirantis/k8s-netchecker-server:v1.2.2
- docker.io/mirantis/k8s-netchecker-agent:v1.2.2
- docker.io/library/registry:2.7.1
- docker.io/library/nginx:1.21.4
- docker.io/library/haproxy:2.4.9
- docker.io/kubernetesui/metrics-scraper:v1.0.7
- docker.io/kubernetesui/dashboard-amd64:v2.4.0
- docker.io/kubeovn/kube-ovn:v1.8.1
- docker.io/k8scloudprovider/cinder-csi-plugin:v1.22.0
- docker.io/cloudnativelabs/kube-router:v1.3.2
- docker.io/amazon/aws-ebs-csi-driver:v0.5.0
- docker.io/amazon/aws-alb-ingress-controller:v1.1.9
 
<!-- Kubespray Use List End -->


### kubespray-sample.env 설명
 
custom 된 kubespray 는 환경 설정 값을 기준으로 실행됨
 
```ShellSession
# playcekube_kubespray
# env file
#MODE [DEPLOY, UPGRADE, RESET, SCALE, REMOVE-NODE, JUST-INVENTORY]
# 배포, 업그레이드, 리셋, 스케일 아웃, 스케일 다운, 인벤토리만 생성
MODE=DEPLOY
# 노드에 대한 정보만 있으면 inventory 를 자동으로 생성한다
CREATE_INVENTORY=true
# 클러스터 이름 기준으로 inventory 가 생기는데 같은 클러스터가 있을 경우 지우고 새로만들 것인지 배포 실패 할 것인지에 대한 옵션
FORCE_CREATE_INVENTORY=true
# cluster name, inventory name
CLUSTER_NAME=playcek8s
# node password
#NODE_PASSWD=password
 
#CLUSTER_RUNTIME [containerd, docker, crio]
# 기본값은 containerd docker의 경우 container 에서 사용할 ip 대역을 미리 설정하여 ip 부족 및 라우팅 문제가 발생할 수 있음
#CLUSTER_RUNTIME=containerd
#SERVICE_NETWORK=10.233.0.0/18
#POD_NETWORK=10.233.64.0/18
# 사설 dns 서버 주소. 일반적으로 deployer 서버 IP
PRIVATE_DNS=172.30.0.20
# 사설 repository 서버. 도메인 기반으로 설정되어 있으며 일반적으로 deployer 서버 (http, https 둘다 제공)
PRIVATE_REPO=repositories.playcekube.local
# 사설 registry 서버. 도메인 기반으로 설정되어 있으며 일반적으로 deployer 서버 (5000번 포트를 사용하지만 https 이며 인증서 설정으로 인하여 별도의 insecure 설정을 하지 않아도 된다)
PRIVATE_REGISTRY=registry.playcekube.local:5000
# 사설 ntp 서버 chronyd 데몬이며 일반적으로 deployer 서버
PRIVATE_NTP=172.30.0.20
# proxy 를 사용하여 배포를 해야할 경우 셋팅. 프록시서버의 ip:port
#PROXY_SERVER=127.0.0.1:3128

# 인벤토리를 생성해야 할 경우 마스터노드들에 대한 정보 hostname:ip 이며 여러개의 경우 구분자는 , 사이에 공백이 있으면 안된다
MASTERS=playcekube-master01:172.30.0.21
# 인벤토리를 생성해야 할 경우 워커노드들에 대한 정보 hostname:ip 이며 여러개의 경우 구분자는 , 사이에 공백이 있으면 안된다
WORKERS=playcekube-worker01:172.30.0.31,playcekube-worker02:172.30.0.32
# ingress 는 기본적으로 설치되며 ingress 라벨이 되어 있는 노드에 설치된다. ingress 라벨을 붙일 노드의 hostname만 적으며 구분자는 , 사이에 공백이 있으면 역시 안된다
INGRESSES=playcekube-master01
# MODE가 SCALE 일때 사용. 구분자는 , 사이에 공백이 있으면 안된다
#NEW_WORKERS=
# MODE가 REMOVE-NODE 일때 사용. 구분자는 , 사이에 공백이 있으면 안된다
#REMOVE_NODES=
```
 
### kubespray 실행

스크립트 파일을 실행 시킬때 환경 설정파일을 같이 넣는다(ex: kubespray-sample.env)  
추가로 -e 옵션으로도 개별 환경 설정을 넣을 수 있다 
 
```ShellSession
/playcecloud/playcekube/deployer/scripts/playcekube_kubespray.sh -f kubespray-sample.env -e MODE=DEPLOY
```

