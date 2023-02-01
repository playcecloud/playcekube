#!/bin/bash
BASEDIR=$(dirname $(readlink -f $0))

# PLAYCE CONF
PLAYCE_DIR=/playcecloud
if [ -f ${PLAYCE_DIR}/playcecloud.conf ]; then
  . ${PLAYCE_DIR}/playcecloud.conf
fi

# chart info
CHART_NAMESPACE=playcekube
CHART_NAME=ingress-nginx
CHART_VERSION=4.1.4

# get installed-values.yaml
helm show values playcekube/${CHART_NAME} > ${BASEDIR}/installed-values.yaml

# using cluster name
USING_CONTEXT=${1}
USING_CONTEXT=${USING_CONTEXT:=$(kubectl config current-context)}
USING_CLUSTER=${USING_CONTEXT#*@}


# installed-values.yaml private registry setting
sed -i "s|registry: .*|registry: registry.local.cloud:5000|g" ${BASEDIR}/installed-values.yaml
sed -i "s|digest: .*|digest: \"\"|g" ${BASEDIR}/installed-values.yaml

# extra arguments
grep -A 8 -n "arguments to pass to nginx-ingress-controller" ${BASEDIR}/installed-values.yaml | grep "extraArgs:" | sed "s/\([0-9]*\).*/\1/g" | xargs -i sed -i "{}s/extraArgs: .*/extraArgs: { enable-ssl-passthrough: true }/" ${BASEDIR}/installed-values.yaml

# config
#sed -i "s|^  config:.*|  config:\n    http2_max_field_size: 64k|g" ${BASEDIR}/installed-values.yaml

# nodeSelector
grep -A 2 -n "nodeSelector:" ${BASEDIR}/installed-values.yaml | grep "kubernetes.io/os:" | sed "s/\([0-9]*\).*/\1/g" | xargs -i sed -i "{}s|kubernetes.io/os: .*|node-role.kubernetes.io/ingress: \"\"|g" ${BASEDIR}/installed-values.yaml
sed -i "s|tolerations: \[\]|tolerations: \[operator: \"Exists\"\]|g" ${BASEDIR}/installed-values.yaml

# default ingress controller
grep -A 8 -n "ingressClassResource:" ${BASEDIR}/installed-values.yaml | grep "default:" | sed "s/\([0-9]*\).*/\1/g" | xargs -i sed -i "{}s/default: .*/default: true/" ${BASEDIR}/installed-values.yaml
sed -i "s|watchIngressWithoutClass: .*|watchIngressWithoutClass: true|g" ${BASEDIR}/installed-values.yaml

# no use service 
grep -A 5 -n "service:" ${BASEDIR}/installed-values.yaml | grep "enabled:" | sed "s/\([0-9]*\).*/\1/g" | xargs -i sed -i "{}s/enabled: .*/enabled: false/" ${BASEDIR}/installed-values.yaml

# daemonset
sed -i "s|kind: .*|kind: DaemonSet|g" ${BASEDIR}/installed-values.yaml

# hostPort
grep -A 5 -n "hostPort:" ${BASEDIR}/installed-values.yaml | grep "enabled:" | sed "s/\([0-9]*\).*/\1/g" | xargs -i sed -i "{}s/enabled: .*/enabled: true/" ${BASEDIR}/installed-values.yaml

# install
helm --kube-context=${USING_CONTEXT} upgrade -i ${CHART_NAME} playcekube/${CHART_NAME} -n ${CHART_NAMESPACE} \
 -f ${BASEDIR}/installed-values.yaml

# ready check
POD_NAME=$(kubectl --context=${USING_CONTEXT} -n ${CHART_NAMESPACE} get pod -o name -l app.kubernetes.io/name=${CHART_NAME} | grep controller | head -n 1)
kubectl --context=${USING_CONTEXT} -n ${CHART_NAMESPACE} wait --for=condition=Ready ${POD_NAME} --timeout=300s

