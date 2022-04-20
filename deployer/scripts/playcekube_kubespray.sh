#!/bin/sh
BASEDIR=$(dirname $(readlink -f $0))

if [ -f ${BASEDIR}/../../playcekube.conf ]; then
  . ${BASEDIR}/../../playcekube.conf
fi

FULLOPT=
# set env file
while getopts ":f:e:" OPT; do
  case ${OPT} in
    f) KUBESPRAY_ENV=${OPTARG}
    FULLOPT="${FULLOPT} --env-file ${OPTARG}"
    ;;
    *) FULLOPT="${FULLOPT} -${OPT} ${OPTARG}"
    ;;
  esac
done

# usage
if [[ "${FULLOPT}" == "" ]] || [[ "${KUBESPRAY_ENV}" == "" ]]; then
  echo "Usage: ex)"
  echo "  playcekube_kubespray.sh -f KUBESPRAY-ENVFILE [-e ENVKEY=ENVVALUE]..."
  exit 1;
fi

KUBERUNID=$(docker run -it -d \
  --pull always \
  -v ${PLAYCE_DATADIR}/kubespray/inventory:/kubespray/inventory \
  -v ${PLAYCE_DIR}/playcekube/deployer/certification/CA/playcekube_rootca.crt:/kubespray/playcekube_rootca.crt \
  -v ${PLAYCE_DIR}/playcekube/deployer/kubespray/kubespray_ssh:/kubespray/kubespray_ssh \
  -v ${PLAYCE_DIR}/playcekube/deployer/kubespray/kubespray_ssh.pub:/kubespray/kubespray_ssh.pub \
  -e PLAYCE_DIR=${PLAYCE_DIR} \
  -e PLAYCE_DOMAIN=${PLAYCE_DOMAIN} \
  -e DEPLOYER_SERVER=${PLAYCE_DEPLOYER} \
  -e CURRENT_DIR=$(pwd) \
  -e KUBESPRAY_ENV=${KUBESPRAY_ENV} \
  ${FULLOPT} \
  registry.${PLAYCE_DOMAIN}:5000/kubespray/playce-kubespray:${PLAYCEKUBE_VERSION} \
  /kubespray/run_kubespray.sh)

echo "### Starting Kubesrpay..."
docker logs -f ${KUBERUNID}

