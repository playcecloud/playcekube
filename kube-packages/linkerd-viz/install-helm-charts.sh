#!/bin/sh
BASEDIR=$(dirname $(readlink -f $0))

if [ -f ${BASEDIR}/../../playcekube.conf ]; then
  . ${BASEDIR}/../../playcekube.conf
fi

# clean
helm uninstall linkerd-viz -n linkerd-viz
rm -rf ${BASEDIR}/installed-values.yaml
kubectl delete ns linkerd-viz

# copy installed-values.yaml
cp -rp ${BASEDIR}/values.yaml ${BASEDIR}/installed-values.yaml

# current cluster name
CURRENT_CLUSTER=$(kubectl config current-context | sed "s/.*@\(.*\)/\1/")

# installed-values.yaml private registry setting
## linkerd-viz
sed -i "s|registry: \"\"|registry: registry.${PLAYCE_DOMAIN}:5000/linkerd|g" ${BASEDIR}/installed-values.yaml
sed -i "s|registry: prom|registry: registry.${PLAYCE_DOMAIN}:5000/prom|g" ${BASEDIR}/installed-values.yaml

# namespace setting
## linkerd2
sed -i "s/^namespace: .*/namespace: linkerd-viz/" ${BASEDIR}/installed-values.yaml
sed -i "s/^linkerdNamespace: .*/linkerdNamespace: linkerd/" ${BASEDIR}/installed-values.yaml
sed -i "s/^installNamespace: .*/installNamespace: false/" ${BASEDIR}/installed-values.yaml
# enforce host
sed -i "s/enforcedHostRegexp: .*/enforcedHostRegexp: linkerd.${CURRENT_CLUSTER}.${PLAYCE_DOMAIN}/" ${BASEDIR}/installed-values.yaml

# create namespace
kubectl create ns linkerd-viz

# create tls linkerd
${PLAYCE_DIR}/playcekube/deployer/certification/01-create-ca-signed-cert.sh linkerd.${CURRENT_CLUSTER}.${PLAYCE_DOMAIN} DNS:linkerd.${CURRENT_CLUSTER}.${PLAYCE_DOMAIN}

# create tls secret
kubectl -n linkerd-viz create secret tls linkerd-tls --cert=${PLAYCE_DIR}/playcekube/deployer/certification/certs/linkerd.${CURRENT_CLUSTER}.${PLAYCE_DOMAIN}.crt --key=${PLAYCE_DIR}/playcekube/deployer/certification/certs/linkerd.${CURRENT_CLUSTER}.${PLAYCE_DOMAIN}.key

# install
helm install linkerd-viz playcekube/linkerd-viz -n linkerd-viz -f ${BASEDIR}/installed-values.yaml

