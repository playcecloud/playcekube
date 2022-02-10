#!/bin/sh
BASEDIR=$(dirname $(readlink -f $0))

if [ -f ${BASEDIR}/../../playcekube.conf ]; then
  . ${BASEDIR}/../../playcekube.conf
fi

# clean
helm uninstall elasticsearch -n logging
rm -rf ${BASEDIR}/installed-values.yaml
kubectl delete ns logging

# copy installed-values.yaml
cp -rp ${BASEDIR}/values.yaml ${BASEDIR}/installed-values.yaml

# current cluster name
CURRENT_CLUSTER=$(kubectl config current-context | sed "s/.*@\(.*\)/\1/")

# installed-values.yaml private registry setting
sed -i "s|image: \"docker\.elastic\.co/\(.*\)\"|image: \1|g" ${BASEDIR}/installed-values.yaml
sed -i "s|image: \(.*\)|image: registry.${PLAYCE_DOMAIN}:5000/\1|g" ${BASEDIR}/installed-values.yaml
sed -i "s|repository: \"docker\.elastic\.co/\(.*\)\"|repository: \1|g" ${BASEDIR}/installed-values.yaml
sed -i "s|repository: \(.*\)|repository: registry.${PLAYCE_DOMAIN}:5000/\1|g" ${BASEDIR}/installed-values.yaml

# installed-values.yaml persistence disable
grep -A 3 -n "^persistence:" ${BASEDIR}/installed-values.yaml | grep "enabled:" | sed "s/\([0-9]*\).*/\1/g" | xargs -i sed -i "{}s/enabled: .*/enabled: false/" ${BASEDIR}/installed-values.yaml

# replicas = 1
sed -i "s/^replicas: .*/replicas: 1/g" ${BASEDIR}/installed-values.yaml

# curator elasticsearch host
grep -A 13 -n "^elasticsearch-curator:" ${BASEDIR}/installed-values.yaml | grep "\- CHANGEME.host" | sed "s/\([0-9]*\).*/\1/g" | xargs -i sed -i "{}s/- CHANGEME.host/- elasticsearch-master/" ${BASEDIR}/installed-values.yaml

# create tls kibana
${PLAYCE_DIR}/playcekube/deployer/certification/01-create-ca-signed-cert.sh kibana.${CURRENT_CLUSTER}.${PLAYCE_DOMAIN} DNS:kibana.${CURRENT_CLUSTER}.${PLAYCE_DOMAIN}

# create namespace
kubectl create ns logging

# create tls secret
# kibana
kubectl -n logging create secret tls kibana-tls --cert=${PLAYCE_DIR}/playcekube/deployer/certification/certs/kibana.${CURRENT_CLUSTER}.${PLAYCE_DOMAIN}.crt --key=${PLAYCE_DIR}/playcekube/deployer/certification/certs/kibana.${CURRENT_CLUSTER}.${PLAYCE_DOMAIN}.key

# kibana ingress enable
grep -A 15 -n "^kibana:" ${BASEDIR}/installed-values.yaml | grep "enabled:" | sed "s/\([0-9]*\).*/\1/g" | xargs -i sed -i "{}s/enabled: .*/enabled: true/" ${BASEDIR}/installed-values.yaml
# kibana ingress hosts
grep -A 15 -n "^kibana:" ${BASEDIR}/installed-values.yaml | grep "\- host:" | sed "s/\([0-9]*\).*/\1/g" | xargs -i sed -i "{}s/- host: .*/- host: kibana.${CURRENT_CLUSTER}.${PLAYCE_DOMAIN}/" ${BASEDIR}/installed-values.yaml
# kibana ingress tls
grep -A 15 -n "^kibana:" ${BASEDIR}/installed-values.yaml | grep "\- secretName:" | sed "s/\([0-9]*\).*/\1/g" | xargs -i sed -i "{}s/- secretName: .*/- secretName: kibana-tls/" ${BASEDIR}/installed-values.yaml
grep -A 15 -n "^kibana:" ${BASEDIR}/installed-values.yaml | grep -A 5 "tls:" | grep "hosts:" | sed "s/\([0-9]*\).*/\1/g" | xargs -i sed -i "{}s/\(.*\)hosts:/\1hosts:\n\1  - kibana.${CURRENT_CLUSTER}.${PLAYCE_DOMAIN}/" ${BASEDIR}/installed-values.yaml
grep -A 15 -n "^kibana:" ${BASEDIR}/installed-values.yaml | grep "\- chart-example.local" | sed "s/\([0-9]*\).*/\1/g" | xargs -i sed -i "{}d" ${BASEDIR}/installed-values.yaml

# install
helm install elasticsearch playcekube/elasticsearch -n logging -f ${BASEDIR}/installed-values.yaml

