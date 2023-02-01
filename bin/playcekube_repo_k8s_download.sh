#!/bin/bash
BASEDIR=$(dirname $(readlink -f $0))

# PLAYCE CONF
PLAYCE_DIR=/playcecloud
if [ -f ${PLAYCE_DIR}/playcecloud.conf ]; then
  . ${PLAYCE_DIR}/playcecloud.conf
fi

# create repository directories
mkdir -p ${PLAYCE_DATADIR}/repositories/kubernetes/{calico,containerd,runc,nerdctl,cri-tools,cni,etcd,helm,crun,kata-containers}

# download file & images
KUBESPRAY_VERSION_LIST="v2.15.1 v2.16.0 v2.17.1 v2.18.0 v2.18.1"
for KUBESPRAY_TAG in ${KUBESPRAY_VERSION_LIST}
do
  echo "[INFO] create filelist.txt for kubespray ${KUBESPRAY_TAG}"
  docker run --rm -it quay.io/kubespray/kubespray:${KUBESPRAY_TAG} bash -c 'cat /kubespray/roles/kubespray-defaults/defaults/main.yaml' > ${BASEDIR}/tmp-kubespray-defaults.yaml
  docker run --rm -it quay.io/kubespray/kubespray:${KUBESPRAY_TAG} bash -c 'cat /kubespray/roles/download/defaults/main.yml' > ${BASEDIR}/tmp-kubespray-download.yaml

  WINCRLF=$(printf '\r')
  KUBE_VERSION=$(grep -R "^kube_version:" ${BASEDIR}/tmp-kubespray-*.yaml | sed "s/.*:kube_version: \(.*\)/\1/")
  KUBE_VERSION=${KUBE_VERSION//\"/}
  KUBE_VERSION=${KUBE_VERSION//\'/}
  KUBE_VERSION=${KUBE_VERSION//${WINCRLF}/}
  CALICO_VERSION=$(grep -R "^calico_version:" ${BASEDIR}/tmp-kubespray-*.yaml | sed "s/.*:calico_version: \(.*\)/\1/")
  CALICO_VERSION=${CALICO_VERSION//\"/}
  CALICO_VERSION=${CALICO_VERSION//\'/}
  CALICO_VERSION=${CALICO_VERSION//${WINCRLF}/}
  ETCD_VERSION=$(grep -R "^etcd_version:" ${BASEDIR}/tmp-kubespray-*.yaml | sed "s/.*:etcd_version: \(.*\)/\1/")
  ETCD_VERSION=${ETCD_VERSION//\"/}
  ETCD_VERSION=${ETCD_VERSION//\'/}
  ETCD_VERSION=${ETCD_VERSION//${WINCRLF}/}
  CONTAINERD_VERSION=$(grep -R "^containerd_version:" ${BASEDIR}/tmp-kubespray-*.yaml | sed "s/.*:containerd_version: \(.*\)/\1/")
  CONTAINERD_VERSION=${CONTAINERD_VERSION//\"/}
  CONTAINERD_VERSION=${CONTAINERD_VERSION//\'/}
  CONTAINERD_VERSION=${CONTAINERD_VERSION//${WINCRLF}/}
  RUNC_VERSION=$(grep -R "^runc_version:" ${BASEDIR}/tmp-kubespray-*.yaml | sed "s/.*:runc_version: \(.*\)/\1/")
  RUNC_VERSION=${RUNC_VERSION//\"/}
  RUNC_VERSION=${RUNC_VERSION//\'/}
  RUNC_VERSION=${RUNC_VERSION//${WINCRLF}/}
  CRUN_VERSION=$(grep -R "^crun_version:" ${BASEDIR}/tmp-kubespray-*.yaml | sed "s/.*:crun_version: \(.*\)/\1/")
  CRUN_VERSION=${CRUN_VERSION//\"/}
  CRUN_VERSION=${CRUN_VERSION//\'/}
  CRUN_VERSION=${CRUN_VERSION//${WINCRLF}/}
  CNI_VERSION=$(grep -R "^cni_version:" ${BASEDIR}/tmp-kubespray-*.yaml | sed "s/.*:cni_version: \(.*\)/\1/")
  CNI_VERSION=${CNI_VERSION//\"/}
  CNI_VERSION=${CNI_VERSION//\'/}
  CNI_VERSION=${CNI_VERSION//${WINCRLF}/}
  NERDCTL_VERSION=$(grep -R "^nerdctl_version:" ${BASEDIR}/tmp-kubespray-*.yaml | sed "s/.*:nerdctl_version: \(.*\)/\1/")
  NERDCTL_VERSION=${NERDCTL_VERSION//\"/}
  NERDCTL_VERSION=${NERDCTL_VERSION//\'/}
  NERDCTL_VERSION=${NERDCTL_VERSION//${WINCRLF}/}
  CRICTL_VERSION=${KUBE_VERSION%.*}.0
  KATA_VERSION=$(grep -R "^kata_containers_version:" ${BASEDIR}/tmp-kubespray-*.yaml | sed "s/.*:kata_containers_version: \(.*\)/\1/")
  KATA_VERSION=${KATA_VERSION//\"/}
  KATA_VERSION=${KATA_VERSION//\'/}
  KATA_VERSION=${KATA_VERSION//${WINCRLF}/}
  HELM_VERSION=$(grep -R "^helm_version:" ${BASEDIR}/tmp-kubespray-*.yaml | sed "s/.*:helm_version: \(.*\)/\1/")
  HELM_VERSION=${HELM_VERSION//\"/}
  HELM_VERSION=${HELM_VERSION//\'/}
  HELM_VERSION=${HELM_VERSION//${WINCRLF}/}

cat << EOF > ${PLAYCE_DIR}/playcekube/kubespray/templates/${KUBESPRAY_TAG}/filelist.txt
https://storage.googleapis.com/kubernetes-release/release/${KUBE_VERSION}/bin/linux/amd64/kubelet;${KUBE_VERSION}/kubelet
https://storage.googleapis.com/kubernetes-release/release/${KUBE_VERSION}/bin/linux/amd64/kubectl;${KUBE_VERSION}/kubectl
https://storage.googleapis.com/kubernetes-release/release/${KUBE_VERSION}/bin/linux/amd64/kubeadm;${KUBE_VERSION}/kubeadm
https://github.com/coreos/etcd/releases/download/${ETCD_VERSION}/etcd-${ETCD_VERSION}-linux-amd64.tar.gz;etcd/etcd-${ETCD_VERSION}-linux-amd64.tar.gz
https://github.com/containernetworking/plugins/releases/download/${CNI_VERSION}/cni-plugins-linux-amd64-${CNI_VERSION}.tgz;cni/cni-plugins-linux-amd64-${CNI_VERSION}.tgz
https://github.com/projectcalico/calicoctl/releases/download/${CALICO_VERSION}/calicoctl-linux-amd64;calico/${CALICO_VERSION}/calicoctl-linux-amd64
https://github.com/projectcalico/calico/archive/${CALICO_VERSION}.tar.gz;calico/${CALICO_VERSION}.tar.gz
https://github.com/kubernetes-sigs/cri-tools/releases/download/${CRICTL_VERSION}/crictl-${CRICTL_VERSION}-linux-amd64.tar.gz;cri-tools/crictl-${CRICTL_VERSION}-linux-amd64.tar.gz
https://get.helm.sh/helm-${HELM_VERSION}-linux-amd64.tar.gz;helm/helm-${HELM_VERSION}-linux-amd64.tar.gz
https://github.com/opencontainers/runc/releases/download/${RUNC_VERSION}/runc.amd64;runc/${RUNC_VERSION}/runc.amd64
https://github.com/containers/crun/releases/download/${CRUN_VERSION}/crun-${CRUN_VERSION}-linux-amd64;crun/crun-${CRUN_VERSION}-linux-amd64
https://github.com/kata-containers/kata-containers/releases/download/${KATA_VERSION}/kata-static-${KATA_VERSION}-x86_64.tar.xz;kata-containers/kata-static-${KATA_VERSION}-x86_64.tar.xz
https://github.com/containerd/nerdctl/releases/download/v${NERDCTL_VERSION}/nerdctl-${NERDCTL_VERSION}-linux-amd64.tar.gz;nerdctl/v${NERDCTL_VERSION}/nerdctl-${NERDCTL_VERSION}-linux-amd64.tar.gz
https://github.com/containerd/containerd/releases/download/v${CONTAINERD_VERSION}/containerd-${CONTAINERD_VERSION}-linux-amd64.tar.gz;containerd/v${CONTAINERD_VERSION}/containerd-${CONTAINERD_VERSION}-linux-amd64.tar.gz
EOF

  # -- 인 경우는 없는 파일
  sed -i "/\-\-/d" ${PLAYCE_DIR}/playcekube/kubespray/templates/${KUBESPRAY_TAG}/filelist.txt

  echo "[INFO] download filelist for kubespray ${KUBESPRAY_TAG}"
  mkdir -p ${PLAYCE_DATADIR}/repositories/kubernetes/${KUBE_VERSION}
  mkdir -p ${PLAYCE_DATADIR}/repositories/kubernetes/calico/${CALICO_VERSION}
  mkdir -p ${PLAYCE_DATADIR}/repositories/kubernetes/runc/${RUNC_VERSION}
  mkdir -p ${PLAYCE_DATADIR}/repositories/kubernetes/nerdctl/v${NERDCTL_VERSION}
  mkdir -p ${PLAYCE_DATADIR}/repositories/kubernetes/containerd/v${CONTAINERD_VERSION}

  for fileinfo in $(cat ${PLAYCE_DIR}/playcekube/kubespray/templates/${KUBESPRAY_TAG}/filelist.txt)
  do
    filearr=(${fileinfo//;/ })
    curl -L ${filearr[0]} -o ${PLAYCE_DATADIR}/repositories/kubernetes/${filearr[1]} 2> /dev/null
  done

  echo "[INFO] create imagelist.txt for kubespray ${KUBESPRAY_TAG}"

  if [ "${KUBESPRAY_TAG}" == "v2.17.1" ] || [ "${KUBESPRAY_TAG}" == "v2.18.0" ] || [ "${KUBESPRAY_TAG}" == "v2.18.1" ]; then
    docker run --rm -it quay.io/kubespray/kubespray:${KUBESPRAY_TAG} bash -c 'WINCRLF=$(printf "\r"); \
      sed -i "s/${WINCRLF}//g" /kubespray/contrib/offline/generate_list.sh; \
      sed -i "s/${WINCRLF}//g" /kubespray/roles/download/defaults/main.yml; \
      sed -i "s/${WINCRLF}//g" /kubespray/roles/kubespray-defaults/defaults/main.yaml; \
      chmod 755 /kubespray/contrib/offline/generate_list.sh; \
      /kubespray/contrib/offline/generate_list.sh > /dev/null 2>&1; \
      cat /kubespray/contrib/offline/temp/images.list;' > ${PLAYCE_DIR}/playcekube/kubespray/templates/${KUBESPRAY_TAG}/imagelist.txt
    WINCRLF=$(printf "\r")
    sed -i "s/${WINCRLF}//g" ${PLAYCE_DIR}/playcekube/kubespray/templates/${KUBESPRAY_TAG}/imagelist.txt
    echo "quay.io/kubespray/kubespray:${KUBESPRAY_TAG}" >> ${PLAYCE_DIR}/playcekube/kubespray/templates/${KUBESPRAY_TAG}/imagelist.txt
  else
    chmod 755 ${PLAYCE_DATADIR}/repositories/kubernetes/${KUBE_VERSION}/kubeadm
    ${PLAYCE_DATADIR}/repositories/kubernetes/${KUBE_VERSION}/kubeadm config images list --kubernetes-version ${KUBE_VERSION} > ${PLAYCE_DIR}/playcekube/kubespray/templates/${KUBESPRAY_TAG}/imagelist.txt
    echo "quay.io/calico/node:${CALICO_VERSION}" >> ${PLAYCE_DIR}/playcekube/kubespray/templates/${KUBESPRAY_TAG}/imagelist.txt
    echo "quay.io/calico/cni:${CALICO_VERSION}" >> ${PLAYCE_DIR}/playcekube/kubespray/templates/${KUBESPRAY_TAG}/imagelist.txt
    echo "quay.io/calico/pod2daemon-flexvol:${CALICO_VERSION}" >> ${PLAYCE_DIR}/playcekube/kubespray/templates/${KUBESPRAY_TAG}/imagelist.txt
    echo "quay.io/calico/kube-controllers:${CALICO_VERSION}" >> ${PLAYCE_DIR}/playcekube/kubespray/templates/${KUBESPRAY_TAG}/imagelist.txt
    echo "quay.io/calico/typha:${CALICO_VERSION}" >> ${PLAYCE_DIR}/playcekube/kubespray/templates/${KUBESPRAY_TAG}/imagelist.txt
    echo "quay.io/kubespray/kubespray:${KUBESPRAY_TAG}" >> ${PLAYCE_DIR}/playcekube/kubespray/templates/${KUBESPRAY_TAG}/imagelist.txt
  fi

  echo "[INFO] pull & push imagelist for kubespray ${KUBESPRAY_TAG}"
  # pull & push
  for cimg in $(cat ${PLAYCE_DIR}/playcekube/kubespray/templates/${KUBESPRAY_TAG}/imagelist.txt)
  do
    docker pull -q ${cimg}
    docker tag ${cimg} $(echo ${cimg} | sed "s/\([^\/]*\)\/\(.*\)/registry.local.cloud:5000\/\2/g")
    docker push -q $(echo ${cimg} | sed "s/\([^\/]*\)\/\(.*\)/registry.local.cloud:5000\/\2/g")
  done

  # rmi
  for cimg in $(cat ${PLAYCE_DIR}/playcekube/kubespray/templates/${KUBESPRAY_TAG}/imagelist.txt)
  do
    docker rmi $(echo ${cimg} | sed "s/\([^\/]*\)\/\(.*\)/registry.local.cloud:5000\/\2/g")
  done
done

rm -rf ${BASEDIR}/tmp-kubespray-*.yaml


cat << EOF > /tmp/tmpimagelist.txt
docker.io/rancher/rancher-agent:v2.6.6
docker.io/rancher/shell:v0.1.16
EOF

echo "[INFO] pull & push rancher agent image"
# pull & push
for cimg in $(cat /tmp/tmpimagelist.txt)
do
  docker pull -q ${cimg}
  docker tag ${cimg} $(echo ${cimg} | sed "s/\([^\/]*\)\/\(.*\)/registry.local.cloud:5000\/\2/g")
  docker push -q $(echo ${cimg} | sed "s/\([^\/]*\)\/\(.*\)/registry.local.cloud:5000\/\2/g")
done

# rmi
for cimg in $(cat /tmp/tmpimagelist.txt)
do
  docker rmi $(echo ${cimg} | sed "s/\([^\/]*\)\/\(.*\)/registry.local.cloud:5000\/\2/g")
done

rm -rf /tmp/tmpimagelist.txt

# latest helm chart download
curl -L https://get.helm.sh/helm-v3.10.2-linux-amd64.tar.gz -o ${PLAYCE_DATADIR}/repositories/kubernetes/helm/helm-v3.10.2-linux-amd64.tar.gz

