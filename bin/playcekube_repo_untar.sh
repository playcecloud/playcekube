#!/bin/bash

# sh config
BASEDIR=$(dirname $(readlink -f $0))

# PLAYCE CONF
PLAYCE_DIR=/playcecloud
if [ -f ${PLAYCE_DIR}/playcecloud.conf ]; then
  . ${PLAYCE_DIR}/playcecloud.conf
fi

# untar file list set
TARFILELIST="PlayceCloudData.OSRepo.centos7.${PLAYCEKUBE_VERSION}.tar PlayceCloudData.OSRepo.rocky8.${PLAYCEKUBE_VERSION}.tar PlayceCloudData.OSRepo.focal.${PLAYCEKUBE_VERSION}.tar PlayceCloudData.OSRepo.jammy.${PLAYCEKUBE_VERSION}.tar PlayceCloudData.K8SRepo.${PLAYCEKUBE_VERSION}.tar PlayceCloudData.K8SRegistry.${PLAYCEKUBE_VERSION}.tar"

# file check & untar
for TARFILE in ${TARFILELIST}
do
  FILEPATH=${PLAYCE_DIR}/srcdata/${TARFILE}

  if [ -f ${FILEPATH} ]; then
    echo "[INFO] ######## PlayceCloud data ${TARFILE} untar start ########"

    FILESIZE=`du -sk --apparent-size ${FILEPATH}  | cut -f 1`;
    CHECKPOINT=$((${FILESIZE}/50));
    echo "Estimated: [==================================================]";
    echo -n "Progess:   [";
    tar xfp ${FILEPATH} \
      --record-size=1K --checkpoint="${CHECKPOINT}" --checkpoint-action="ttyout=>" \
      -C ${PLAYCE_DIR}
    echo "]"
    mv ${FILEPATH} ${FILEPATH}.done

    echo "[INFO] ######## PlayceCloud data ${TARFILE} untar end ########"
  fi
done

if [ -d "${PLAYCE_DATADIR}/repositories/rocky8" ] && [ ! -d "${PLAYCE_DATADIR}/repositories/centos8" ]; then
  ln -s ${PLAYCE_DATADIR}/repositories/rocky8 ${PLAYCE_DATADIR}/repositories/centos8
fi


