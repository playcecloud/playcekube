#!/bin/bash

# sh config
BASEDIR=$(dirname $(readlink -f $0))

# PLAYCE CONF
PLAYCE_DIR=/playcecloud
if [ -f ${PLAYCE_DIR}/playcecloud.conf ]; then
  . ${PLAYCE_DIR}/playcecloud.conf
fi

# binary copy
echo "[INFO] ######## Kubernetes utils copy ########"
echo "[INFO] copy kubectl"
K8S_VERSION=v1.22.8
cp --remove-destination ${PLAYCE_DIR}/data/repositories/kubernetes/${K8S_VERSION}/kubectl /usr/local/bin/kubectl
chmod 755 /usr/local/bin/kubectl
kubectl completion bash > /etc/bash_completion.d/kubectl
sed -i "/alias kc=kubectl/d" ~/.bashrc
sed -i "/complete -F __start_kubectl/d" ~/.bashrc
echo "alias kc=kubectl" >> ~/.bashrc
echo "complete -F __start_kubectl kc" >> ~/.bashrc

echo "[INFO] copy helm"
HELM_TARFILE=$(ls -vr ${PLAYCE_DIR}/data/repositories/kubernetes/helm/ | head -n 1)
tar zxfp ${PLAYCE_DIR}/data/repositories/kubernetes/helm/${HELM_TARFILE} linux-amd64/helm
mv -f linux-amd64/helm /usr/local/bin/helm
rm -rf linux-amd64
helm completion bash > /etc/bash_completion.d/helm

# argocd cli install
echo "[INFO] copy argocd cli"
rm -rf /usr/local/bin/argocd
cp -rp ${PLAYCE_DATADIR}/repositories/kubernetes/argocd/argocd /usr/local/bin/argocd
chmod 755 /usr/local/bin/argocd

# helm chart install
echo "[INFO] install helm chart"
helm repo index ${PLAYCE_DATADIR}/repositories/helm-charts --url https://repository.local.cloud/helm-charts
helm repo add --force-update playcekube https://repository.local.cloud/helm-charts

# playcekube shell
echo "[INFO] link playcekube"
if [ -f /usr/local/bin/playcekube ]; then
  unlink /usr/local/bin/playcekube
fi
ln -s ${PLAYCE_DIR}/playcekube/bin/playcekube.sh /usr/local/bin/playcekube

# ssh-key-copy
echo "[INFO] copy ssh-key"
# ssh keygen
if [ ! -f "${PLAYCE_DIR}/playcekube/kubespray/kubespray_ssh" ] || [ ! -f "${PLAYCE_DIR}/playcekube/kubespray/kubespray_ssh.pub" ]; then
  echo "[INFO] create ssh-key"
  rm -rf ${PLAYCE_DIR}/playcekube/kubespray/kubespray_ssh*
  ssh-keygen -N "" -t rsa -f ${PLAYCE_DIR}/playcekube/kubespray/kubespray_ssh
fi
mkdir -p ~/.ssh
touch ~/.ssh/authorized_keys
sed -i "/$(cat ${PLAYCE_DIR}/playcekube/kubespray/kubespray_ssh.pub | sed 's|/|\\/|g')/d" ~/.ssh/authorized_keys
cat ${PLAYCE_DIR}/playcekube/kubespray/kubespray_ssh.pub >> ~/.ssh/authorized_keys

