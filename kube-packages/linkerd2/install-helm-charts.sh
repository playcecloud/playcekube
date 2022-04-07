#!/bin/sh
BASEDIR=$(dirname $(readlink -f $0))

if [ -f ${BASEDIR}/../../playcekube.conf ]; then
  . ${BASEDIR}/../../playcekube.conf
fi

# clean
helm uninstall linkerd -n linkerd 2> /dev/null
rm -rf ${BASEDIR}/installed-values.yaml 2> /dev/null
kubectl delete ns linkerd 2> /dev/null

# copy installed-values.yaml
cp -rp ${BASEDIR}/values.yaml ${BASEDIR}/installed-values.yaml

# current cluster name
CURRENT_CLUSTER=$(kubectl config current-context | sed "s/.*@\(.*\)/\1/")

# installed-values.yaml private registry setting
## linkerd2
sed -i "s|name: cr.l5d.io|name: registry.${PLAYCE_DOMAIN}:5000|g" ${BASEDIR}/installed-values.yaml
sed -i "s|controllerImage: cr.l5d.io|controllerImage: registry.${PLAYCE_DOMAIN}:5000|g" ${BASEDIR}/installed-values.yaml

# namespace setting
## linkerd2
sed -i "s/^namespace: .*/namespace: linkerd/" ${BASEDIR}/installed-values.yaml
sed -i "s/^installNamespace: .*/installNamespace: false/" ${BASEDIR}/installed-values.yaml

# heartbeat disable
sed -i "s/disableHeartBeat: false/disableHeartBeat: true/" ${BASEDIR}/installed-values.yaml

# create namespace
kubectl create ns linkerd

# create tls issuer
sed -i "/CN=linkerd2-issuer/d" ${PLAYCE_DIR}/playcekube/deployer/certification/CA/playcekube_rootca.index
rm -rf ${PLAYCE_DIR}/playcekube/deployer/certification/intermediateCA/linkerd2-issuer.*
${PLAYCE_DIR}/playcekube/deployer/certification/00-create-intermediate-ca.sh linkerd2-issuer

# install
helm upgrade --install linkerd playcekube/linkerd2 \
 -n linkerd \
 --set-file identityTrustAnchorsPEM=${PLAYCE_DIR}/playcekube/deployer/certification/intermediateCA/linkerd2-issuer.crt \
 --set-file identity.issuer.tls.crtPEM=${PLAYCE_DIR}/playcekube/deployer/certification/intermediateCA/linkerd2-issuer.crt \
 --set-file identity.issuer.tls.keyPEM=${PLAYCE_DIR}/playcekube/deployer/certification/intermediateCA/linkerd2-issuer.key \
 --set identity.issuer.crtExpiry=$(date -d '+8760 hour' +"%Y-%m-%dT%H:%M:%SZ") \
 -f ${BASEDIR}/installed-values.yaml

# Ready check
kubectl wait --for=condition=available deployment.apps/linkerd-destination -n linkerd

