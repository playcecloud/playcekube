#!/bin/bash
BASEDIR=$(dirname $(readlink -f $0))

# PLAYCE CONF
PLAYCE_DIR=/playcecloud
if [ -f ${PLAYCE_DIR}/playcecloud.conf ]; then
  . ${PLAYCE_DIR}/playcecloud.conf
fi

# chart info
CHART_NAMESPACE=playcekube-dev
CHART_NAME=tekton-pipeline
CHART_VERSION=v0.32.1

# get installed-values.yaml
helm show values playcekube/${CHART_NAME} > ${BASEDIR}/installed-values.yaml

# using cluster name
USING_CONTEXT=${1}
USING_CONTEXT=${USING_CONTEXT:=$(kubectl config current-context)}
USING_CLUSTER=${USING_CONTEXT#*@}


# installed-values.yaml private registry setting
## tekton
sed -i "s|registry: .*|registry: registry.local.cloud:5000|" ${BASEDIR}/installed-values.yaml

# ingress enable
grep -A 3 -n "^tekton-dashboard:" ${BASEDIR}/installed-values.yaml | grep "enabled:" | sed "s/\([0-9]*\).*/\1/g" | xargs -i sed -i "{}s/enabled: .*/enabled: true/" ${BASEDIR}/installed-values.yaml
# ingress hosts
grep -A 20 -n "^tekton-dashboard:" ${BASEDIR}/installed-values.yaml | grep "host: .*" | sed "s/\([0-9]*\).*/\1/g" | xargs -i sed -i "{}s/host: .*/host: tekton.${USING_CLUSTER}.${PLAYCE_DOMAIN}/" ${BASEDIR}/installed-values.yaml
# ingress tls
grep -A 20 -n "^tekton-dashboard:" ${BASEDIR}/installed-values.yaml | grep "tls:" | sed "s/\([0-9]*\).*/\1/g" | xargs -i sed -i "{}s/\(.*\)tls: .*/\1tls:\n\1  - secretName: wild-tls\n\1    hosts:\n\1      - tekton.${USING_CLUSTER}.${PLAYCE_DOMAIN}/" ${BASEDIR}/installed-values.yaml

# install
helm --kube-context=${USING_CONTEXT} upgrade -i ${CHART_NAME} playcekube/${CHART_NAME} -n ${CHART_NAMESPACE} \
 -f ${BASEDIR}/installed-values.yaml

# cli install
tar xf ${BASEDIR}/tkn_0.21.0_Linux_x86_64.tar.gz -C /usr/local/bin/ tkn

tkn completion bash > /etc/bash_completion.d/tkn

