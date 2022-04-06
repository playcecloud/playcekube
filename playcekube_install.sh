#!/bin/bash
BASEDIR=$(dirname $(readlink -f $0))

if [ -f ${BASEDIR}/playcekube.conf ]; then
  . ${BASEDIR}/playcekube.conf
fi

# function call
. ${PLAYCE_DIR}/playcekube/deployer/scripts/playcekube_common.sh
# check info
RELEASE_NUM=$(getReleaseNumber)

# busybox mode run
chmod 755 ${PLAYCE_DIR}/playcekube/bin/busybox

# os repository check & untar
if ! checkRepositoryOSData && [ -f ${PLAYCE_DIR}/downloadsrc/PlayceKubeData.OSRepo.${PLAYCEKUBE_VERSION}.${RELEASE_NUM}.tar ]; then
  echo "# repository os data untar"
  ${PLAYCE_DIR}/playcekube/bin/busybox tar xfp ${PLAYCE_DIR}/downloadsrc/PlayceKubeData.OSRepo.${PLAYCEKUBE_VERSION}.${RELEASE_NUM}.tar -C ${PLAYCE_DIR}
fi

# kubernetes repository check & untar
if ! checkRepositoryKubernetesData && ! checkRepositoryHelmChartsData && ! checkRepositoryCrioData && ! checkRepositoryDockerData && [ -f ${PLAYCE_DIR}/downloadsrc/PlayceKubeData.K8SRepo.${PLAYCEKUBE_VERSION}.${RELEASE_NUM}.tar ]; then
  echo "# kubernetes repository data untar"
  ${PLAYCE_DIR}/playcekube/bin/busybox tar xfp ${PLAYCE_DIR}/downloadsrc/PlayceKubeData.K8SRepo.${PLAYCEKUBE_VERSION}.${RELEASE_NUM}.tar -C ${PLAYCE_DIR}
fi
# registry check & untar
if ! checkRegistryData && [ -f ${PLAYCE_DIR}/downloadsrc/PlayceKubeData.Registry.${PLAYCEKUBE_VERSION}.${RELEASE_NUM}.tar ]; then
  echo "# registry data untar"
  ${PLAYCE_DIR}/playcekube/bin/busybox tar xfp ${PLAYCE_DIR}/downloadsrc/PlayceKubeData.Registry.${PLAYCEKUBE_VERSION}.${RELEASE_NUM}.tar -C ${PLAYCE_DIR}
fi

# data check or error
if ! isOnline && ! checkAllData; then
  echo "data directory or data file not found"
  exit 1
fi

# service config
echo "######## PlayceKube service config ########"
${PLAYCE_DIR}/playcekube/deployer/scripts/playcekube_service_config.sh
echo "######## PlayceKube service config complete ########"

# check install docker
if ! isActiveDocker; then
  exit 1;
fi

# service start
echo "######## PlayceKube service start ########"
${PLAYCE_DIR}/playcekube/deployer/scripts/playcekube_service_start.sh
echo "######## PlayceKube service started ########"

# check service
if ! isActiveDNS || ! isActiveRepository || ! isActiveRegistry; then
  exit 1;
fi

# binary copy
echo "######## Kubernetes utils copy ########"
echo "# copy kubectl"
K8S_VERSION=${PLAYCEKUBE_VERSION/k/}
if [ ! -f "${PLAYCE_DIR}/data/repositories/kubernetes/${K8S_VERSION}/kubectl" ]; then
  mkdir -p ${PLAYCE_DIR}/data/repositories/kubernetes/${K8S_VERSION}
  cd ${PLAYCE_DIR}/data/repositories/kubernetes/${K8S_VERSION}
  curl -LO https://dl.k8s.io/release/v1.23.0/bin/linux/amd64/kubectl
fi

cp --remove-destination ${PLAYCE_DIR}/data/repositories/kubernetes/${K8S_VERSION}/kubectl /usr/local/bin/kubectl
chmod 755 /usr/local/bin/kubectl
kubectl completion bash > /etc/bash_completion.d/kubectl
echo "alias kc=kubectl" >> ~/.bashrc
echo "complete -F __start_kubectl kc" >> ~/.bashrc

echo "# copy helm"
HELM_TARFILE=$(ls ${PLAYCE_DIR}/data/repositories/kubernetes/helm/ | head -n 1)
if [ ! -f "${PLAYCE_DIR}/data/repositories/kubernetes/helm/${HELM_TARFILE}" ]; then
  mkdir -p ${PLAYCE_DIR}/data/repositories/kubernetes/helm
  cd ${PLAYCE_DIR}/data/repositories/kubernetes/helm
  curl -LO https://get.helm.sh/helm-v3.7.2-linux-amd64.tar.gz
  HELM_TARFILE=helm-v3.7.2-linux-amd64.tar.gz
fi

tar zxfp ${PLAYCE_DIR}/data/repositories/kubernetes/helm/${HELM_TARFILE} linux-amd64/helm
mv -f linux-amd64/helm /usr/local/bin/helm
rm -rf linux-amd64
helm completion bash > /etc/bash_completion.d/helm

# helm chart install
echo "# install helm chart"
helm repo index ${PLAYCE_DATADIR}/repositories/helm-charts --url https://repositories.${PLAYCE_DOMAIN}/helm-charts
helm repo add --force-update playcekube https://repositories.${PLAYCE_DOMAIN}/helm-charts

# playcekube shell
echo "# link playcekube"
unlink /usr/local/bin/playcekube
ln -s ${PLAYCE_DIR}/playcekube/deployer/scripts/playcekube.sh /usr/local/bin/playcekube

# ssh-key-copy
echo "# copy ssh-key"
mkdir -p ~/.ssh
touch ~/.ssh/authorized_keys
sed -i "/$(cat /playcecloud/playcekube/deployer/kubespray/kubespray_ssh.pub | sed 's|/|\\/|g')/d" ~/.ssh/authorized_keys
cat ${PLAYCE_DIR}/playcekube/deployer/kubespray/kubespray_ssh.pub >> ~/.ssh/authorized_keys

echo ""
echo "######## PlayceKube installed successfully ########"
echo ""

