#!/bin/sh
BASEDIR=$(dirname $(readlink -f $0))

if [ -f ${BASEDIR}/../../playcekube.conf ]; then
  . ${BASEDIR}/../../playcekube.conf
fi

# clean
helm uninstall playce-argo -n argo
rm -rf ${BASEDIR}/installed-values.yaml
kubectl delete ns argo

