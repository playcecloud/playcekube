#!/bin/sh
BASEDIR=$(dirname $(readlink -f $0))

if [ -f ${BASEDIR}/../../playcekube.conf ]; then
  . ${BASEDIR}/../../playcekube.conf
fi

# clean
helm uninstall playce-argo -n argo
rm -rf ${BASEDIR}/installed-values.yaml
kubectl delete ns argo

# copy installed-values.yaml
cp -rp ${BASEDIR}/values.yaml ${BASEDIR}/installed-values.yaml

# current cluster name
CURRENT_CLUSTER=$(kubectl config current-context | sed "s/.*@\(.*\)/\1/")

# installed-values.yaml private registry setting
grep -n "repository:" ${BASEDIR}/installed-values.yaml | grep -Ev "ghcr.io|docker.io|k8s.gcr.io|quay.io|gcr.io" | grep -v "/" | grep -v '""' | sed "s/\([0-9]*\).*/\1/g" | xargs -i sed -i  "{}s/repository: \(.*\)/repository: docker.io\/library\/\1/g" ${BASEDIR}/installed-values.yaml
grep -n "repository:" ${BASEDIR}/installed-values.yaml | grep -Ev "ghcr.io|docker.io|k8s.gcr.io|quay.io|gcr.io" | grep "/" | grep -v '""' | sed "s/\([0-9]*\).*/\1/g" | xargs -i sed -i  "{}s/repository: \(.*\)/repository: docker.io\/\1/g" ${BASEDIR}/installed-values.yaml
sed -i "s|repository: [^/]*/\(.*\)|repository: registry.${PLAYCE_DOMAIN}:5000/\1|g" ${BASEDIR}/installed-values.yaml

# create namespace
kubectl create ns argo

# create tls argo
${PLAYCE_DIR}/playcekube/deployer/certification/01-create-ca-signed-cert.sh argo.${CURRENT_CLUSTER}.${PLAYCE_DOMAIN} DNS:argo.${CURRENT_CLUSTER}.${PLAYCE_DOMAIN}
kubectl -n argo create secret tls argo-tls --cert=${PLAYCE_DIR}/playcekube/deployer/certification/certs/argo.${CURRENT_CLUSTER}.${PLAYCE_DOMAIN}.crt --key=${PLAYCE_DIR}/playcekube/deployer/certification/certs/argo.${CURRENT_CLUSTER}.${PLAYCE_DOMAIN}.key

# install
helm upgrade -i playce-argo playcekube/argo-cd -n argo \
 -f ${BASEDIR}/installed-values.yaml \
 --set server.extraArgs[0]="--insecure" \
 --set server.ingress.enabled=true \
 --set server.ingress.hosts[0]=argo.${CURRENT_CLUSTER}.${PLAYCE_DOMAIN} \
 --set server.ingress.tls[0].hosts[0]=argo.${CURRENT_CLUSTER}.${PLAYCE_DOMAIN} \
 --set server.ingress.tls[0].secretName=argo-tls

