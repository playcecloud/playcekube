#!/bin/sh
BASEDIR=$(dirname $(readlink -f $0))

if [ -f ${BASEDIR}/../../playcekube.conf ]; then
  . ${BASEDIR}/../../playcekube.conf
fi

# clean
helm uninstall keycloak -n keycloak
rm -rf ${BASEDIR}/installed-values.yaml
kubectl delete ns keycloak

# copy installed-values.yaml
cp -rp ${BASEDIR}/values.yaml ${BASEDIR}/installed-values.yaml

# current cluster name
CURRENT_CLUSTER=$(kubectl config current-context | sed "s/.*@\(.*\)/\1/")

# installed-values.yaml private registry setting
grep -A 3 -n "^global:" ${BASEDIR}/installed-values.yaml | grep "imageRegistry:" | sed "s/\([0-9]*\).*/\1/g" | xargs -i sed -i "{}s/imageRegistry: .*/imageRegistry: registry.${PLAYCE_DOMAIN}:5000/" ${BASEDIR}/installed-values.yaml

# secret
sed -i "s/adminUser: .*/adminUser: admin/g" ${BASEDIR}/installed-values.yaml
sed -i "s/adminPassword: .*/adminPassword: oscadmin/g" ${BASEDIR}/installed-values.yaml

# installed-values.yaml persistence volume false settting
sed -i "/^postgresql:/a\  primary:\n    persistence:\n      enabled: false" ${BASEDIR}/installed-values.yaml

# create tls keycloak
${PLAYCE_DIR}/playcekube/deployer/certification/01-create-ca-signed-cert.sh keycloak.${CURRENT_CLUSTER}.${PLAYCE_DOMAIN} DNS:keycloak.${CURRENT_CLUSTER}.${PLAYCE_DOMAIN}

# create namespace
kubectl create ns keycloak

# create tls secret
kubectl -n keycloak create secret tls keycloak-tls --cert=${PLAYCE_DIR}/playcekube/deployer/certification/certs/keycloak.${CURRENT_CLUSTER}.${PLAYCE_DOMAIN}.crt --key=${PLAYCE_DIR}/playcekube/deployer/certification/certs/keycloak.${CURRENT_CLUSTER}.${PLAYCE_DOMAIN}.key

# keycloak ingress enable
grep -A 5 -n "^service:" ${BASEDIR}/installed-values.yaml | grep "type:" | sed "s/\([0-9]*\).*/\1/g" | xargs -i sed -i "{}s/type: .*/type: ClusterIP/" ${BASEDIR}/installed-values.yaml
grep -A 85 -n "^ingress:" ${BASEDIR}/installed-values.yaml | grep "enabled:" | sed "s/\([0-9]*\).*/\1/g" | xargs -i sed -i "{}s/enabled: .*/enabled: true/" ${BASEDIR}/installed-values.yaml
# keycloak ingress hosts
grep -A 85 -n "^ingress:" ${BASEDIR}/installed-values.yaml | grep "hostname:" | sed "s/\([0-9]*\).*/\1/g" | xargs -i sed -i "{}s/hostname: .*/hostname: keycloak.${CURRENT_CLUSTER}.${PLAYCE_DOMAIN}/" ${BASEDIR}/installed-values.yaml
# keycloak ingress tls
sed -i "s/^proxyAddressForwarding: .*/proxyAddressForwarding: true/" ${BASEDIR}/installed-values.yaml
grep -A 85 -n "^ingress:" ${BASEDIR}/installed-values.yaml | grep "tls:" | sed "s/\([0-9]*\).*/\1/g" | xargs -i sed -i "{}s/tls: .*/tls: true/" ${BASEDIR}/installed-values.yaml
grep -A 85 -n "^ingress:" ${BASEDIR}/installed-values.yaml | grep "  extraTls:" | sed "s/\([0-9]*\).*/\1/g" | xargs -i sed -i "{}s/\(.*\)extraTls:.*/\1extraTls:\n\1  - hosts:\n\1      - keycloak.${CURRENT_CLUSTER}.${PLAYCE_DOMAIN}\n\1    secretName: keycloak-tls/" ${BASEDIR}/installed-values.yaml

# install
helm install keycloak playcekube/keycloak -n keycloak -f ${BASEDIR}/installed-values.yaml

