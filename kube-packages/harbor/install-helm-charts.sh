#!/bin/sh
BASEDIR=$(dirname $(readlink -f $0))

if [ -f ${BASEDIR}/../../playcekube.conf ]; then
  . ${BASEDIR}/../../playcekube.conf
fi

# clean
helm uninstall harbor -n harbor
rm -rf ${BASEDIR}/installed-values.yaml
kubectl delete ns harbor

# copy installed-values.yaml
cp -rp ${BASEDIR}/values.yaml ${BASEDIR}/installed-values.yaml

# change clusterDomain
CURRENT_CLUSTER=$(kubectl config current-context | sed "s/.*@\(.*\)/\1/")
# not change clustetDomain value
#sed -i "s/^clusterDomain: .*/clusterDomain: ${CURRENT_CLUSTER}/" ${BASEDIR}/installed-values.yaml

# installed-values.yaml private registry setting
## harbor
sed -i "s/imageRegistry: .*/imageRegistry: registry.${PLAYCE_DOMAIN}:5000/" ${BASEDIR}/installed-values.yaml
## etc images
sed -i "s/registry: .*/registry: registry.${PLAYCE_DOMAIN}:5000/g" ${BASEDIR}/installed-values.yaml

# installed-values.yaml persistence volume false settting
grep -A 3 -n "persistence:" ${BASEDIR}/installed-values.yaml | grep "enabled:" | sed "s/\([0-9]*\).*/\1/g" | sort -r -n | xargs -i sed -i "{}s/enabled:.*/enabled: false/g" ${BASEDIR}/installed-values.yaml

# admin password
sed -i "s/harborAdminPassword: .*/harborAdminPassword: oscadmin/g" ${BASEDIR}/installed-values.yaml

# create tls harbor
${PLAYCE_DIR}/playcekube/deployer/certification/01-create-ca-signed-cert.sh harbor.${CURRENT_CLUSTER}.${PLAYCE_DOMAIN} DNS:core.harbor.${CURRENT_CLUSTER}.${PLAYCE_DOMAIN},DNS:notary.harbor.${CURRENT_CLUSTER}.${PLAYCE_DOMAIN},DNS:harbor.${CURRENT_CLUSTER}.${PLAYCE_DOMAIN}

# create namespace
kubectl create ns harbor

# create tls secret
kubectl -n harbor create secret tls harbor-tls --cert=${PLAYCE_DIR}/playcekube/deployer/certification/certs/harbor.${CURRENT_CLUSTER}.${PLAYCE_DOMAIN}.crt --key=${PLAYCE_DIR}/playcekube/deployer/certification/certs/harbor.${CURRENT_CLUSTER}.${PLAYCE_DOMAIN}.key

# service mode ingress
grep -A 3 -n "^service:" ${BASEDIR}/installed-values.yaml | grep "type:" | sed "s/\([0-9]*\).*/\1/g" | xargs -i sed -i "{}s/type: .*/type: Ingress/" ${BASEDIR}/installed-values.yaml

# tls secret setting
grep -A 20 -n "^service:" ${BASEDIR}/installed-values.yaml | grep "existingSecret:" | sed "s/\([0-9]*\).*/\1/g" | xargs -i sed -i "{}s/existingSecret: .*/existingSecret: harbor-tls/" ${BASEDIR}/installed-values.yaml
grep -A 20 -n "^service:" ${BASEDIR}/installed-values.yaml | grep "notaryExistingSecret:" | sed "s/\([0-9]*\).*/\1/g" | xargs -i sed -i "{}s/notaryExistingSecret: .*/notaryExistingSecret: harbor-tls/" ${BASEDIR}/installed-values.yaml

# ingress enable
grep -A 3 -n "^ingress:" ${BASEDIR}/installed-values.yaml | grep "enabled:" | sed "s/\([0-9]*\).*/\1/g" | xargs -i sed -i "{}s/enabled: .*/enabled: true/" ${BASEDIR}/installed-values.yaml

# ingress hosts setting
grep -A 20 -n "^ingress:" ${BASEDIR}/installed-values.yaml | grep "core:" | sed "s/\([0-9]*\).*/\1/g" | xargs -i sed -i "{}s/core: .*/core: harbor.${CURRENT_CLUSTER}.${PLAYCE_DOMAIN}/" ${BASEDIR}/installed-values.yaml
grep -A 20 -n "^ingress:" ${BASEDIR}/installed-values.yaml | grep "notary:" | sed "s/\([0-9]*\).*/\1/g" | xargs -i sed -i "{}s/notary: .*/notary: notary.harbor.${CURRENT_CLUSTER}.${PLAYCE_DOMAIN}/" ${BASEDIR}/installed-values.yaml
sed -i "s|^externalURL: .*|externalURL: https://harbor.${CURRENT_CLUSTER}.${PLAYCE_DOMAIN}|g" ${BASEDIR}/installed-values.yaml

# install
helm install harbor playcekube/harbor -n harbor -f ${BASEDIR}/installed-values.yaml

