#!/bin/sh
BASEDIR=$(dirname $(readlink -f $0))

if [ -f ${BASEDIR}/../../playcekube.conf ]; then
  . ${BASEDIR}/../../playcekube.conf
fi

# clean
helm uninstall csi-driver-nfs -n csi-driver-nfs
rm -rf ${BASEDIR}/installed-values.yaml
kubectl delete ns csi-driver-nfs

