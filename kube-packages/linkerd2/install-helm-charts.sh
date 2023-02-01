#!/bin/bash
BASEDIR=$(dirname $(readlink -f $0))

# PLAYCE CONF
PLAYCE_DIR=/playcecloud
if [ -f ${PLAYCE_DIR}/playcecloud.conf ]; then
  . ${PLAYCE_DIR}/playcecloud.conf
fi

# chart info
CHART_NAMESPACE=playcekube
CHART_NAME=linkerd2
CHART_VERSION=2.11.1

# get installed-values.yaml
helm show values playcekube/${CHART_NAME} > ${BASEDIR}/installed-values.yaml

# using cluster name
USING_CONTEXT=${1}
USING_CONTEXT=${USING_CONTEXT:=$(kubectl config current-context)}
USING_CLUSTER=${USING_CONTEXT#*@}


# installed-values.yaml private registry setting
## linkerd2
sed -i "s|name: cr.l5d.io|name: registry.local.cloud:5000|g" ${BASEDIR}/installed-values.yaml
sed -i "s|controllerImage: cr.l5d.io|controllerImage: registry.local.cloud:5000|g" ${BASEDIR}/installed-values.yaml

# namespace setting
## linkerd2
sed -i "s/^namespace: .*/namespace: ${CHART_NAMESPACE}/" ${BASEDIR}/installed-values.yaml
sed -i "s/^installNamespace: .*/installNamespace: false/" ${BASEDIR}/installed-values.yaml

# heartbeat disable
sed -i "s/disableHeartBeat: false/disableHeartBeat: true/" ${BASEDIR}/installed-values.yaml

# install
helm --kube-context=${USING_CONTEXT} upgrade -i ${CHART_NAME} playcekube/${CHART_NAME} -n ${CHART_NAMESPACE} \
 -f ${BASEDIR}/installed-values.yaml \
 --set-file identityTrustAnchorsPEM=${PLAYCE_DATADIR}/certificates/certs/linkerd2-issuer.crt \
 --set-file identity.issuer.tls.crtPEM=${PLAYCE_DATADIR}/certificates/certs/linkerd2-issuer.crt \
 --set-file identity.issuer.tls.keyPEM=${PLAYCE_DATADIR}/certificates/certs/linkerd2-issuer.key \
 --set identity.issuer.crtExpiry=$(date -d '+8760 hour' +"%Y-%m-%dT%H:%M:%SZ")

# Ready check
kubectl --context=${USING_CONTEXT} -n ${CHART_NAMESPACE} wait --for=condition=available deployment.apps/linkerd-destination --timeout=300s

