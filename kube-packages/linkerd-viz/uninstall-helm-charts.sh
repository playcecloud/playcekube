#!/bin/bash
BASEDIR=$(dirname $(readlink -f $0))

# PLAYCE CONF
PLAYCE_DIR=/playcecloud
if [ -f ${PLAYCE_DIR}/playcecloud.conf ]; then
  . ${PLAYCE_DIR}/playcecloud.conf
fi

# chart info
CHART_NAMESPACE=playcekube
CHART_NAME=linkerd-viz
CHART_VERSION=2.11.1

# using cluster name
USING_CONTEXT=${1}
USING_CONTEXT=${USING_CONTEXT:=$(kubectl config current-context)}
USING_CLUSTER=${USING_CONTEXT#*@}

# clean
kubectl delete ingress linkerd-dashboard -n ${CHART_NAMESPACE}
helm --kube-context=${USING_CONTEXT} uninstall ${CHART_NAME} -n ${CHART_NAMESPACE}
rm -rf ${BASEDIR}/installed-values.yaml

