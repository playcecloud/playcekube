#!/bin/bash
BASEDIR=$(dirname $(readlink -f $0))

# PLAYCE CONF
PLAYCE_DIR=/playcecloud
if [ -f ${PLAYCE_DIR}/playcecloud.conf ]; then
  . ${PLAYCE_DIR}/playcecloud.conf
fi

# chart info
CHART_NAMESPACE=playcekube-dev
CHART_NAME=jenkins
CHART_VERSION=4.1.12

# get installed-values.yaml
helm show values playcekube/${CHART_NAME} > ${BASEDIR}/installed-values.yaml

# using cluster name
USING_CONTEXT=${1}
USING_CONTEXT=${USING_CONTEXT:=$(kubectl config current-context)}
USING_CLUSTER=${USING_CONTEXT#*@}

# ingress enable
grep -A 30 -n " ingress:" ${BASEDIR}/installed-values.yaml | grep "enabled:" | sed "s/\([0-9]*\).*/\1/g" | xargs -i sed -i "{}s/enabled: .*/enabled: true/" ${BASEDIR}/installed-values.yaml
# prometheus ingress hosts
grep -A 30 -n " ingress:" ${BASEDIR}/installed-values.yaml | grep "hostName:" | sed "s/\([0-9]*\).*/\1/g" | xargs -i sed -i "{}s/\(.*\)hostName:.*/\1hostName: jenkins.${USING_CLUSTER}.${PLAYCE_DOMAIN}/" ${BASEDIR}/installed-values.yaml
# prometheus ingress tls
grep -A 30 -n " ingress:" ${BASEDIR}/installed-values.yaml | grep "tls:" | sed "s/\([0-9]*\).*/\1/g" | xargs -i sed -i "{}s/\(.*\)tls:.*/\1tls:\n\1  - secretName: wild-tls\n\1    hosts:\n\1      - jenkins.${USING_CLUSTER}.${PLAYCE_DOMAIN}/" ${BASEDIR}/installed-values.yaml

# install
helm --kube-context=${USING_CONTEXT} upgrade -i ${CHART_NAME} playcekube/${CHART_NAME} -n ${CHART_NAMESPACE} \
 -f ${BASEDIR}/installed-values.yaml

