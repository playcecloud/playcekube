#!/bin/bash
BASEDIR=$(dirname $(readlink -f $0))

# PLAYCE CONF
PLAYCE_DIR=/playcecloud
if [ -f ${PLAYCE_DIR}/playcecloud.conf ]; then
  . ${PLAYCE_DIR}/playcecloud.conf
fi

# chart info
CHART_NAMESPACE=playcekube-dev
CHART_NAME=argo-events
CHART_VERSION=2.0.3

# get installed-values.yaml
helm show values playcekube/${CHART_NAME} > ${BASEDIR}/installed-values.yaml

# using cluster name
USING_CONTEXT=${1}
USING_CONTEXT=${USING_CONTEXT:=$(kubectl config current-context)}
USING_CLUSTER=${USING_CONTEXT#*@}


# installed-values.yaml private registry setting
grep -n "repository:" ${BASEDIR}/installed-values.yaml | grep -Ev "ghcr.io|docker.io|k8s.gcr.io|quay.io|gcr.io" | grep -v "/" | grep -v '""' | sed "s/\([0-9]*\).*/\1/g" | xargs -i sed -i  "{}s/repository: \(.*\)/repository: docker.io\/library\/\1/g" ${BASEDIR}/installed-values.yaml
grep -n "repository:" ${BASEDIR}/installed-values.yaml | grep -Ev "ghcr.io|docker.io|k8s.gcr.io|quay.io|gcr.io" | grep "/" | grep -v '""' | sed "s/\([0-9]*\).*/\1/g" | xargs -i sed -i  "{}s/repository: \(.*\)/repository: docker.io\/\1/g" ${BASEDIR}/installed-values.yaml
sed -i "s|repository: [^/]*/\(.*\)|repository: \1|g" ${BASEDIR}/installed-values.yaml

# playcekube ca mount
sed -i "s|volumeMounts: \[\]|volumeMounts:\n    - name: root-ca\n      mountPath: /etc/ssl/certs|g" ${BASEDIR}/installed-values.yaml
sed -i "s|volumes: \[\]|volumes:\n    - name: root-ca\n      secret:\n        secretName: os-root-ca|g" ${BASEDIR}/installed-values.yaml

# install
helm --kube-context=${USING_CONTEXT} upgrade -i ${CHART_NAME} playcekube/${CHART_NAME} -n ${CHART_NAMESPACE} \
 -f ${BASEDIR}/installed-values.yaml \
 --set server.ingress.enabled=true \
 --set server.ingress.hosts[0]=argo.${USING_CLUSTER}.${PLAYCE_DOMAIN} \
 --set server.ingress.tls[0].hosts[0]=argo.${USING_CLUSTER}.${PLAYCE_DOMAIN} \
 --set server.ingress.tls[0].secretName=wild-tls

