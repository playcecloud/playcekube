#!/bin/sh
BASEDIR=$(dirname $(readlink -f $0))

if [ -f ${BASEDIR}/../../playcekube.conf ]; then
  . ${BASEDIR}/../../playcekube.conf
fi

function getReleaseVersion()
{
  local releasever=1.0

  if [[ -f "${PLAYCE_DIR}/playcekube/release.txt" ]]; then
    releasever=$(grep "^version:" ${PLAYCE_DIR}/playcekube/release.txt | awk -F "-" '{ print $NF }')
  fi

  echo ${releasever};
}

function getOSFamily()
{
  local osfamily="unknown"
  local osid=$(grep "^ID=" /etc/os-release | sed "s/ID=\(.*\)/\1/g")
  osid=${osid//\"/}

  if [[ "${osid}" =~ rocky|centos|almalinux|rhel ]]; then
    osfamily="centos"
  elif [[ "${osid}" =~ debian|ubuntu ]]; then
    osfamily="debian"
  fi

  echo ${osfamily};
}

function getOSVersion()
{
  local osversion=$(grep "^VERSION_ID=" /etc/os-release | sed "s/VERSION_ID=\(.*\)/\1/g")
  osversion=${osversion//\"/}
  osversion=${osversion%.*}

  echo ${osversion};
}


function isOnline()
{
  local checkresult=$(curl --connect-timeout 3 -I download.docker.com 2> /dev/null)

  if [ "${checkresult}" == "" ]; then
    return 1;
  fi

  return 0; 
}

function isActiveDocker()
{
  # check docker
  ACTCHECK_DOCKER=$(systemctl is-active docker.service)
  if [[ "${ACTCHECK_DOCKER}" != "active" ]]; then
    echo "docker is not started"
    return 1;
  fi

  return 0;
}

function isActiveRepository()
{
  if ! isActiveDocker; then
    echo "repository server not started"
    return 1;
  fi

  CHECK_REPOSITORY=$(docker ps | grep playcekube_repositories)

  if [[ "${CHECK_REPOSITORY}" == "" ]]; then
    echo "repository server not started"
    return 1;
  fi

  return 0;
}

function isActiveDNS()
{
  if ! isActiveDocker; then
    echo "dns server not started"
    return 1;
  fi

  CHECK_NAMED=$(docker ps | grep playcekube_bind9)
  if [[ "${CHECK_NAMED}" == "" ]]; then
    echo "dns server not started"
    return 1;
  fi

  return 0;
}

function isActiveRegistry()
{
  if ! isActiveDocker; then
    echo "registry server not started"
    return 1;
  fi

  CHECK_REGISTRY=$(docker ps | grep playcekube_registry)

  if [[ "${CHECK_REGISTRY}" == "" ]]; then
    echo "registry server not started"
    return 1;
  fi

  return 0;
}

function checkRegistryData()
{
  local data_registry=${PLAYCE_DATADIR}/registry/docker/registry/v2/blobs/sha256

  if [ -d "${data_registry}" ]; then
    return 0;
  fi

  return 1;
}

function checkRepositoryOSData()
{
  local data_repository_os7_base=${PLAYCE_DATADIR}/repositories/centos7/base/repodata
  local data_repository_os7_updates=${PLAYCE_DATADIR}/repositories/centos7/updates/repodata
  local data_repository_os7_extras=${PLAYCE_DATADIR}/repositories/centos7/extras/repodata

  local data_repository_os8_base=${PLAYCE_DATADIR}/repositories/rocky8/baseos/repodata
  local data_repository_os8_appstream=${PLAYCE_DATADIR}/repositories/rocky8/appstream/repodata
  local data_repository_os8_extras=${PLAYCE_DATADIR}/repositories/rocky8/extras/repodata

  if [ "$(getOSVersion)" == "7" ]; then
    if [ -d "${data_repository_os7_base}" ] && [ -d "${data_repository_os7_updates}" ] && [ -d "${data_repository_os7_extras}" ]; then
      return 0;
    fi
  elif [ "$(getOSVersion)" == "8" ]; then
    if [ -d "${data_repository_os8_base}" ] && [ -d "${data_repository_os8_appstream}" ] && [ -d "${data_repository_os8_extras}" ]; then
      return 0;
    fi
  fi

  return 1;
}

function checkRepositoryCrioData()
{
  local data_repository_os7_crio=${PLAYCE_DATADIR}/repositories/centos7/crio/repodata
  local data_repository_os8_crio=${PLAYCE_DATADIR}/repositories/rocky8/crio/repodata

  if [ "$(getOSVersion)" == "7" ]; then
    if [ -d "${data_repository_os7_crio}" ]; then
      return 0;
    fi
  elif [ "$(getOSVersion)" == "8" ]; then
    if [ -d "${data_repository_os8_crio}" ]; then
      return 0;
    fi
  fi

  return 1;
}

function checkRepositoryDockerData()
{
  local data_repository_os7_docker=${PLAYCE_DATADIR}/repositories/centos7/docker-ce-stable/repodata
  local data_repository_os8_docker=${PLAYCE_DATADIR}/repositories/rocky8/docker-ce-stable/repodata

  if [ "$(getOSVersion)" == "7" ]; then
    if [ -d "${data_repository_os7_base}" ] && [ -d "${data_repository_os7_updates}" ] && [ -d "${data_repository_os7_extras}" ]; then
      return 0;
    fi
  elif [ "$(getOSVersion)" == "8" ]; then
    if [ -d "${data_repository_os8_base}" ] && [ -d "${data_repository_os8_appstream}" ] && [ -d "${data_repository_os8_extras}" ]; then
      return 0;
    fi
  fi

  return 1;
}

function checkRepositoryHelmChartsData()
{
  local data_helm_charts=${PLAYCE_DATADIR}/repositories/helm-charts

  if [ -d "${data_helm_charts}" ]; then
    return 0;
  fi

  return 1;
}

function checkRepositoryKubernetesData()
{
  local data_kubernetes=${PLAYCE_DATADIR}/repositories/kubernetes

  if [ -d "${data_kubernetes}" ]; then
    return 0;
  fi

  return 1;
}


function checkAllData()
{
  return $(checkRegistryData) && $(checkRepositoryOSData) && $(checkRepositoryCrioData) && $(checkRepositoryDockerData) && $(checkRepositoryHelmChartsData) && $(checkRepositoryKubernetesData);
}


