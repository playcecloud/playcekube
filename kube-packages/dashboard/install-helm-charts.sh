#!/bin/sh
BASEDIR=$(dirname $(readlink -f $0))

if [ -f ${BASEDIR}/../../playcekube.conf ]; then
  . ${BASEDIR}/../../playcekube.conf
fi

# clean
helm uninstall kubernetes-dashboard -n kubernetes-dashboard 2> /dev/null
rm -rf ${BASEDIR}/installed-values.yaml 2> /dev/null
kubectl delete ns kubernetes-dashboard 2> /dev/null

# copy installed-values.yaml
cp -rp ${BASEDIR}/values.yaml ${BASEDIR}/installed-values.yaml

# current cluster name
CURRENT_CLUSTER=$(kubectl config current-context | sed "s/.*@\(.*\)/\1/")

# installed-values.yaml private registry setting
sed -i "s|repository: quay\.io/\(.*\)|repository: \1|g" ${BASEDIR}/installed-values.yaml
sed -i "s|repository: k8s\.gcr\.io/\(.*\)|repository: \1|g" ${BASEDIR}/installed-values.yaml
sed -i "s|repository: docker\.io/\(.*\)|repository: \1|g" ${BASEDIR}/installed-values.yaml
sed -i "s|repository: \(.*\)|repository: registry.${PLAYCE_DOMAIN}:5000/\1|g" ${BASEDIR}/installed-values.yaml

# create tls kubernetes-dashboard
${PLAYCE_DIR}/playcekube/deployer/certification/01-create-ca-signed-cert.sh dashboard.${CURRENT_CLUSTER}.${PLAYCE_DOMAIN} DNS:dashboard.${CURRENT_CLUSTER}.${PLAYCE_DOMAIN}

# create namespace
kubectl create ns kubernetes-dashboard

# create tls secret
kubectl -n kubernetes-dashboard create secret tls dashboard-tls --cert=${PLAYCE_DIR}/playcekube/deployer/certification/certs/dashboard.${CURRENT_CLUSTER}.${PLAYCE_DOMAIN}.crt --key=${PLAYCE_DIR}/playcekube/deployer/certification/certs/dashboard.${CURRENT_CLUSTER}.${PLAYCE_DOMAIN}.key

# kubernetes-dashboard ingress enable
grep -A 5 -n "^ingress:" ${BASEDIR}/installed-values.yaml | grep "enabled:" | sed "s/\([0-9]*\).*/\1/g" | xargs -i sed -i "{}s/enabled: .*/enabled: true/" ${BASEDIR}/installed-values.yaml
# kubernetes-dashboard ingress hosts
grep -n "^ingress:" ${BASEDIR}/installed-values.yaml | sed "s/\([0-9]*\).*/\1/g" | xargs -i sed -i "{}a\  hosts:\n    - dashboard.${CURRENT_CLUSTER}.${PLAYCE_DOMAIN}" ${BASEDIR}/installed-values.yaml
# kubernetes-dashboard ingress tls
grep -n "^ingress:" ${BASEDIR}/installed-values.yaml | sed "s/\([0-9]*\).*/\1/g" | xargs -i sed -i "{}a\  tls:\n    - secretName: dashboard-tls\n      hosts:\n        - dashboard.${CURRENT_CLUSTER}.${PLAYCE_DOMAIN}" ${BASEDIR}/installed-values.yaml

# install
helm install kubernetes-dashboard playcekube/kubernetes-dashboard -n kubernetes-dashboard -f ${BASEDIR}/installed-values.yaml

