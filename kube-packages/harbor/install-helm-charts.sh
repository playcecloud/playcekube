#!/bin/sh
BASEDIR=$(dirname $(readlink -f $0))

if [ -f ${BASEDIR}/../../playcekube.conf ]; then
  . ${BASEDIR}/../../playcekube.conf
fi

# clean
helm uninstall harbor -n harbor 2> /dev/null
rm -rf ${BASEDIR}/installed-values.yaml 2> /dev/null
kubectl delete ns harbor 2> /dev/null

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
#grep -A 3 -n "persistence:" ${BASEDIR}/installed-values.yaml | grep "enabled:" | sed "s/\([0-9]*\).*/\1/g" | sort -r -n | xargs -i sed -i "{}s/enabled:.*/enabled: false/g" ${BASEDIR}/installed-values.yaml
## postgresql persistence false
#grep -A 20 -n "^postgresql:" ${BASEDIR}/installed-values.yaml | grep "primary:" | sed "s/\([0-9]*\).*/\1/g" | xargs -i sed -i "{}a\    persistence: {enabled: false}" ${BASEDIR}/installed-values.yaml
## redis persistence false
#sed -i "/^redis:/a\  master: {persistence: {enabled: false}}" ${BASEDIR}/installed-values.yaml

# admin password
sed -i "s/^adminPassword: .*/adminPassword: oscadmin/g" ${BASEDIR}/installed-values.yaml

# create tls harbor
${PLAYCE_DIR}/playcekube/deployer/certification/01-create-ca-signed-cert.sh harbor.${CURRENT_CLUSTER}.${PLAYCE_DOMAIN} DNS:core.harbor.${CURRENT_CLUSTER}.${PLAYCE_DOMAIN},DNS:notary.harbor.${CURRENT_CLUSTER}.${PLAYCE_DOMAIN},DNS:harbor.${CURRENT_CLUSTER}.${PLAYCE_DOMAIN}

# create namespace
kubectl create ns harbor

# create tls secret
kubectl -n harbor create secret tls harbor.${CURRENT_CLUSTER}.${PLAYCE_DOMAIN}-tls --cert=${PLAYCE_DIR}/playcekube/deployer/certification/certs/harbor.${CURRENT_CLUSTER}.${PLAYCE_DOMAIN}.crt --key=${PLAYCE_DIR}/playcekube/deployer/certification/certs/harbor.${CURRENT_CLUSTER}.${PLAYCE_DOMAIN}.key

# service mode ClusterIP
grep -A 3 -n "^service:" ${BASEDIR}/installed-values.yaml | grep "type:" | sed "s/\([0-9]*\).*/\1/g" | xargs -i sed -i "{}s/type: .*/type: ClusterIP/" ${BASEDIR}/installed-values.yaml

# ingress enable
sed -i "s/^exposureType: .*/exposureType: ingress/g" ${BASEDIR}/installed-values.yaml

# ingress hosts setting
sed -i "s|^externalURL: .*|externalURL: https://harbor.${CURRENT_CLUSTER}.${PLAYCE_DOMAIN}|g" ${BASEDIR}/installed-values.yaml
## core
grep -A 20 -n "^  core:" ${BASEDIR}/installed-values.yaml | grep "hostname:" | sed "s/\([0-9]*\).*/\1/g" | xargs -i sed -i "{}s/hostname: .*/hostname: harbor.${CURRENT_CLUSTER}.${PLAYCE_DOMAIN}/" ${BASEDIR}/installed-values.yaml
grep -A 90 -n "^  core:" ${BASEDIR}/installed-values.yaml | grep "tls:" | sed "s/\([0-9]*\).*/\1/g" | xargs -i sed -i "{}s/tls: .*/tls: true/" ${BASEDIR}/installed-values.yaml
grep -A 90 -n "^  core:" ${BASEDIR}/installed-values.yaml | grep "  extraTls:" | sed "s/\([0-9]*\).*/\1/g" | xargs -i sed -i "{}s/\(.*\)extraTls:.*/\1extraTls:\n\1  - hosts:\n\1      - harbor.${CURRENT_CLUSTER}.${PLAYCE_DOMAIN}\n\1    secretName: harbor.${CURRENT_CLUSTER}.${PLAYCE_DOMAIN}-tls/" ${BASEDIR}/installed-values.yaml
## notary
grep -A 20 -n "^  notary:" ${BASEDIR}/installed-values.yaml | grep "hostname:" | sed "s/\([0-9]*\).*/\1/g" | xargs -i sed -i "{}s/hostname: .*/hostname: notary.harbor.${CURRENT_CLUSTER}.${PLAYCE_DOMAIN}/" ${BASEDIR}/installed-values.yaml
grep -A 90 -n "^  notary:" ${BASEDIR}/installed-values.yaml | grep "tls:" | sed "s/\([0-9]*\).*/\1/g" | xargs -i sed -i "{}s/tls: .*/tls: true/" ${BASEDIR}/installed-values.yaml
grep -A 90 -n "^  notary:" ${BASEDIR}/installed-values.yaml | grep "  extraTls:" | sed "s/\([0-9]*\).*/\1/g" | xargs -i sed -i "{}s/\(.*\)extraTls:.*/\1extraTls:\n\1  - hosts:\n\1      - notary.harbor.${CURRENT_CLUSTER}.${PLAYCE_DOMAIN}\n\1    secretName: harbor.${CURRENT_CLUSTER}.${PLAYCE_DOMAIN}-tls/" ${BASEDIR}/installed-values.yaml

# install
helm install harbor playcekube/harbor -n harbor -f ${BASEDIR}/installed-values.yaml

