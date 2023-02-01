# kubespray

## 사용 모듈 리스트

- docker ce 20.10.11
- kubespray v2.18.0 branch custom build

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


