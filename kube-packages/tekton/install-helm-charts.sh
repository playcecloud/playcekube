#!/bin/sh
BASEDIR=$(dirname $(readlink -f $0))

if [ -f ${BASEDIR}/../../playcekube.conf ]; then
  . ${BASEDIR}/../../playcekube.conf
fi

# clean
helm uninstall tekton -n tekton
rm -rf ${BASEDIR}/installed-values.yaml
kubectl delete ns tekton

# copy installed-values.yaml
cp -rp ${BASEDIR}/values.yaml ${BASEDIR}/installed-values.yaml

# current cluster name
CURRENT_CLUSTER=$(kubectl config current-context | sed "s/.*@\(.*\)/\1/")

# installed-values.yaml private registry setting
## tekton
sed -i "s|registry: .*|registry: registry.${PLAYCE_DOMAIN}:5000|" ${BASEDIR}/installed-values.yaml

# create tls dashboard
${PLAYCE_DIR}/playcekube/deployer/certification/01-create-ca-signed-cert.sh tekton.${CURRENT_CLUSTER}.${PLAYCE_DOMAIN} DNS:tekton.${CURRENT_CLUSTER}.${PLAYCE_DOMAIN}

# create namespace
kubectl create ns tekton

# create tls secret
kubectl -n tekton create secret tls tekton-tls --cert=${PLAYCE_DIR}/playcekube/deployer/certification/certs/tekton.${CURRENT_CLUSTER}.${PLAYCE_DOMAIN}.crt --key=${PLAYCE_DIR}/playcekube/deployer/certification/certs/tekton.${CURRENT_CLUSTER}.${PLAYCE_DOMAIN}.key

# ingress enable
grep -A 3 -n "^tekton-dashboard:" ${BASEDIR}/installed-values.yaml | grep "enabled:" | sed "s/\([0-9]*\).*/\1/g" | xargs -i sed -i "{}s/enabled: .*/enabled: true/" ${BASEDIR}/installed-values.yaml
# ingress hosts
grep -A 20 -n "^tekton-dashboard:" ${BASEDIR}/installed-values.yaml | grep "host: .*" | sed "s/\([0-9]*\).*/\1/g" | xargs -i sed -i "{}s/host: .*/host: tekton.${CURRENT_CLUSTER}.${PLAYCE_DOMAIN}/" ${BASEDIR}/installed-values.yaml
# ingress tls
grep -A 20 -n "^tekton-dashboard:" ${BASEDIR}/installed-values.yaml | grep "tls:" | sed "s/\([0-9]*\).*/\1/g" | xargs -i sed -i "{}s/\(.*\)tls: .*/\1tls:\n\1  - secretName: tekton-tls\n\1    hosts:\n\1      - tekton.${CURRENT_CLUSTER}.${PLAYCE_DOMAIN}/" ${BASEDIR}/installed-values.yaml

# install
helm install tekton playcekube/tekton-pipeline -n tekton -f ${BASEDIR}/installed-values.yaml

# cli install
tar xf ${BASEDIR}/tkn_0.21.0_Linux_x86_64.tar.gz -C /usr/local/bin/ tkn

tkn completion bash > /etc/bash_completion.d/tkn

