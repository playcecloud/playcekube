#!/bin/bash
BASEDIR=$(dirname $(readlink -f $0))

# PLAYCE CONF
PLAYCE_DIR=/playcecloud
if [ -f ${PLAYCE_DIR}/playcecloud.conf ]; then
  . ${PLAYCE_DIR}/playcecloud.conf
fi

# chart info
CHART_NAMESPACE=playcekube
CHART_NAME=linkerd-jaeger
CHART_VERSION=2.11.1

# get installed-values.yaml
helm show values playcekube/${CHART_NAME} > ${BASEDIR}/installed-values.yaml

# using cluster name
USING_CONTEXT=${1}
USING_CONTEXT=${USING_CONTEXT:=$(kubectl config current-context)}
USING_CLUSTER=${USING_CONTEXT#*@}


# installed-values.yaml private registry setting
## linkerd-jaeger
sed -i "s|name: otel|name: registry.local.cloud:5000/otel|g" ${BASEDIR}/installed-values.yaml
sed -i "s|name: omnition|name: registry.local.cloud:5000/omnition|g" ${BASEDIR}/installed-values.yaml
sed -i "s|name: jaegertracing|name: registry.local.cloud:5000/jaegertracing|g" ${BASEDIR}/installed-values.yaml
sed -i "s|name: cr.l5d.io|name: registry.local.cloud:5000|g" ${BASEDIR}/installed-values.yaml
sed -i "s|name: cr.l5d.io|name: registry.local.cloud:5000|g" ${BASEDIR}/installed-values.yaml

# namespace setting
## linkerd-jaeger
sed -i "s/^namespace: .*/namespace: ${CHART_NAMESPACE}/" ${BASEDIR}/installed-values.yaml
sed -i "s/^linkerdNamespace: .*/linkerdNamespace: ${CHART_NAMESPACE}/" ${BASEDIR}/installed-values.yaml
sed -i "s/^installNamespace: .*/installNamespace: false/" ${BASEDIR}/installed-values.yaml

# install
helm --kube-context=${USING_CONTEXT} upgrade -i ${CHART_NAME} playcekube/${CHART_NAME} -n ${CHART_NAMESPACE} \
 -f ${BASEDIR}/installed-values.yaml

