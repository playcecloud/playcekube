#!/bin/bash
BASEDIR=$(dirname $(readlink -f $0))

if [ -f ${BASEDIR}/playcekube.conf ]; then
  . ${BASEDIR}/playcekube.conf
fi

# function call
. ${PLAYCE_DIR}/playcekube/deployer/scripts/playcekube_common.sh
# check info
RELEASE_NUM=$(getReleaseNumber)

# os repository check & untar
if ! checkRepositoryOSData && [ -f ${PLAYCE_DIR}/downloadsrc/PlayceKubeData.OSRepo.${PLAYCEKUBE_VERSION}.${RELEASE_NUM}.tar ]; then
  echo "# repository os data untar"
  tar xfp ${PLAYCE_DIR}/downloadsrc/PlayceKubeData.OSRepo.${PLAYCEKUBE_VERSION}.${RELEASE_NUM}.tar -C ${PLAYCE_DIR}
fi

# kubernetes repository check & untar
if ! checkRepositoryKubernetesData && ! checkRepositoryHelmChartsData && ! checkRepositoryCrioData && ! checkRepositoryDockerData && [ -f ${PLAYCE_DIR}/downloadsrc/PlayceKubeData.K8SRepo.${PLAYCEKUBE_VERSION}.${RELEASE_NUM}.tar ]; then
  echo "# kubernetes repository data untar"
  tar xfp ${PLAYCE_DIR}/downloadsrc/PlayceKubeData.K8SRepo.${PLAYCEKUBE_VERSION}.${RELEASE_NUM}.tar -C ${PLAYCE_DIR}
fi
# registry check & untar
if ! checkRegistryData && [ -f ${PLAYCE_DIR}/downloadsrc/PlayceKubeData.Registry.${PLAYCEKUBE_VERSION}.${RELEASE_NUM}.tar ]; then
  echo "# registry data untar"
  tar xfp ${PLAYCE_DIR}/downloadsrc/PlayceKubeData.Registry.${PLAYCEKUBE_VERSION}.${RELEASE_NUM}.tar -C ${PLAYCE_DIR}
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

echo ""
echo "######## PlayceKube installed successfully ########"
echo ""

