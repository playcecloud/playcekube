#!/bin/sh
BASEDIR=$(dirname $(readlink -f $0))

if [ -f ${BASEDIR}/../../playcekube.conf ]; then
  . ${BASEDIR}/../../playcekube.conf
fi

# clean
helm uninstall gitea -n gitea 2> /dev/null
rm -rf ${BASEDIR}/installed-values.yaml 2> /dev/null
kubectl delete ns gitea 2> /dev/null

# copy installed-values.yaml
cp -rp ${BASEDIR}/values.yaml ${BASEDIR}/installed-values.yaml

# change clusterDomain
CURRENT_CLUSTER=$(kubectl config current-context | sed "s/.*@\(.*\)/\1/")
# not change clustetDomain value
#sed -i "s/^clusterDomain: .*/clusterDomain: ${CURRENT_CLUSTER}/" ${BASEDIR}/installed-values.yaml

# installed-values.yaml private registry setting
## gitea
sed -i "s|repository: \(.*\)|repository: registry.${PLAYCE_DOMAIN}:5000/\1|" ${BASEDIR}/installed-values.yaml
## memcached
sed -i "/^memcached:/a\  image:\n    registry: registry.${PLAYCE_DOMAIN}:5000" ${BASEDIR}/installed-values.yaml
## postgresql
sed -i "/^postgresql:/a\  image:\n    registry: registry.${PLAYCE_DOMAIN}:5000" ${BASEDIR}/installed-values.yaml
## mysql
sed -i "/^mysql:/a\  image:\n    registry: registry.${PLAYCE_DOMAIN}:5000" ${BASEDIR}/installed-values.yaml
## mariadb
sed -i "/^mariadb:/a\  image:\n    registry: registry.${PLAYCE_DOMAIN}:5000" ${BASEDIR}/installed-values.yaml

# installed-values.yaml persistence volume false settting
grep -A 3 -n "persistence:" ${BASEDIR}/installed-values.yaml | grep "enabled:" | sed "s/\([0-9]*\).*/\1/g" | sort -r -n | xargs -i sed -i "{}d" ${BASEDIR}/installed-values.yaml
sed -i "s/\(.*\)persistence:.*/\1persistence:\n\1  enabled: false/g" ${BASEDIR}/installed-values.yaml

# user setting
grep -A 5 -n "^gitea:" ${BASEDIR}/installed-values.yaml | grep "username:" | sed "s/\([0-9]*\).*/\1/g" | xargs -i sed -i "{}s/username: .*/username: oscadmin/" ${BASEDIR}/installed-values.yaml
grep -A 5 -n "^gitea:" ${BASEDIR}/installed-values.yaml | grep "password:" | sed "s/\([0-9]*\).*/\1/g" | xargs -i sed -i "{}s/password: .*/password: oscadmin/" ${BASEDIR}/installed-values.yaml

# create tls gitea
${PLAYCE_DIR}/playcekube/deployer/certification/01-create-ca-signed-cert.sh gitea.${CURRENT_CLUSTER}.${PLAYCE_DOMAIN} DNS:gitea.${CURRENT_CLUSTER}.${PLAYCE_DOMAIN}

# create namespace
kubectl create ns gitea

# create tls secret
kubectl -n gitea create secret tls gitea-tls --cert=${PLAYCE_DIR}/playcekube/deployer/certification/certs/gitea.${CURRENT_CLUSTER}.${PLAYCE_DOMAIN}.crt --key=${PLAYCE_DIR}/playcekube/deployer/certification/certs/gitea.${CURRENT_CLUSTER}.${PLAYCE_DOMAIN}.key

# ingress enable
grep -A 3 -n "^ingress:" ${BASEDIR}/installed-values.yaml | grep "enabled:" | sed "s/\([0-9]*\).*/\1/g" | xargs -i sed -i "{}s/enabled: .*/enabled: true/" ${BASEDIR}/installed-values.yaml

# ingress hosts setting
grep -A 15 -n "^ingress:" ${BASEDIR}/installed-values.yaml | grep "\- host:" | sed "s/\([0-9]*\).*/\1/g" | xargs -i sed -i "{}s/host: .*/host: gitea.${CURRENT_CLUSTER}.${PLAYCE_DOMAIN}/" ${BASEDIR}/installed-values.yaml
grep -A 15 -n "^ingress:" ${BASEDIR}/installed-values.yaml | grep "tls:" | sed "s/\([0-9]*\).*/\1/g" | xargs -i sed -i "{}s/tls: .*/tls:/" ${BASEDIR}/installed-values.yaml
grep -A 15 -n "^ingress:" ${BASEDIR}/installed-values.yaml | grep "tls:" | sed "s/\([0-9]*\).*/\1/g" | xargs -i sed -i "{}a\    - secretName: gitea-tls\n      hosts:\n        - gitea.${CURRENT_CLUSTER}.${PLAYCE_DOMAIN}" ${BASEDIR}/installed-values.yaml


# install
helm install gitea playcekube/gitea -n gitea -f ${BASEDIR}/installed-values.yaml

