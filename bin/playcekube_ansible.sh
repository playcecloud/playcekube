#!/bin/bash
BASEDIR=$(dirname $(readlink -f $0))

# PLAYCE CONF
PLAYCE_DIR=/playcecloud
if [ -f ${PLAYCE_DIR}/playcecloud.conf ]; then
  . ${PLAYCE_DIR}/playcecloud.conf
fi

FULLOPT=
# set env file
while getopts ":f:e:" OPT; do
  case ${OPT} in
    f) KUBESPRAY_ENV=${OPTARG}
    FULLOPT="${FULLOPT} --env-file ${OPTARG}"
    ;;
    *) FULLOPT="${FULLOPT} ${OPT} ${OPTARG}"
    ;;
  esac
done

# kubespray env
if [ "${KUBESPRAY_ENV}" != "" ]; then
  . $(readlink -f ${KUBESPRAY_ENV})
fi

KUBESPRAY_TAG=v2.18.1
case ${KUBERNETES_VERSION} in
  "v1.19"* )
    KUBESPRAY_TAG=v2.15.1
    ;;
  "v1.20"* )
    KUBESPRAY_TAG=v2.16.0
    ;;
  "v1.21"* )
    KUBESPRAY_TAG=v2.17.1
    ;;
  "v1.22.5" )
    KUBESPRAY_TAG=v2.18.0
    ;;
esac
KUBESPRAY_IMG=registry.local.cloud:5000/kubespray/kubespray:${KUBESPRAY_TAG}

docker run -it --rm \
  --pull always \
  -v ${PLAYCE_DIR}/playcekube/kubespray/templates/${KUBESPRAY_TAG}:/kubespray/inventory.template \
  -v ${PLAYCE_DATADIR}/kubespray/inventory:/kubespray/inventory \
  -v ${PLAYCE_DATADIR}/certificates/ca/playcecloud_rootca.crt:/kubespray/playcecloud_rootca.crt \
  -v ${PLAYCE_DIR}/playcekube/kubespray/kubespray_ssh:/kubespray/kubespray_ssh \
  -v ${PLAYCE_DIR}/playcekube/kubespray/kubespray_ssh.pub:/kubespray/kubespray_ssh.pub \
  -v ${PLAYCE_DIR}/playcekube/kubespray/extfiles:/kubespray/extfiles \
  -e TZ=Asia/Seoul \
  -e PLAYCE_DIR=${PLAYCE_DIR} \
  -e PLAYCE_DOMAIN=${PLAYCE_DOMAIN} \
  -e DEPLOY_SERVER=${PLAYCE_DEPLOY} \
  -e CURRENT_DIR=$(pwd) \
  -e KUBESPRAY_TAG=${KUBESPRAY_TAG} \
  -e KUBESPRAY_ENV=${KUBESPRAY_ENV} \
  ${FULLOPT} \
  ${KUBESPRAY_IMG} \
  /bin/bash

