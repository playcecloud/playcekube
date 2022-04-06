#!/bin/sh
BASEDIR=$(dirname $(readlink -f $0))

if [ -f ${BASEDIR}/../../playcekube.conf ]; then
  . ${BASEDIR}/../../playcekube.conf
fi

# clean
helm uninstall kubeapps -n kubeapps
rm -rf ${BASEDIR}/installed-values.yaml
kubectl delete ns kubeapps

# copy installed-values.yaml
cp -rp ${BASEDIR}/values.yaml ${BASEDIR}/installed-values.yaml

# change clusterDomain
CURRENT_CLUSTER=$(kubectl config current-context | sed "s/.*@\(.*\)/\1/")

# installed-values.yaml private registry setting
grep -A 3 -n "^global:" ${BASEDIR}/installed-values.yaml | grep "imageRegistry:" | sed "s/\([0-9]*\).*/\1/g" | xargs -i sed -i "{}s/imageRegistry: .*/imageRegistry: registry.${PLAYCE_DOMAIN}:5000/" ${BASEDIR}/installed-values.yaml

# initalRepos
grep -A 3 -n "^  initialRepos:" ${BASEDIR}/installed-values.yaml | grep "name:" | sed "s/\([0-9]*\).*/\1/g" | xargs -i sed -i "{}s/name: .*/name: playcekube/" ${BASEDIR}/installed-values.yaml
grep -A 3 -n "^  initialRepos:" ${BASEDIR}/installed-values.yaml | grep "url:" | sed "s/\([0-9]*\).*/\1/g" | xargs -i sed -i "{}s|url: .*|url: https://repositories.${PLAYCE_DOMAIN}/helm-charts|" ${BASEDIR}/installed-values.yaml
CA_TLS_CERTIFICATE=$(sed "s/^\(.*\)/        \1/g" ${PLAYCE_DIR}/playcekube/deployer/certification/CA/playcekube_rootca.crt | sed -E "s|([/+\])|\\\\\1|g" | sed -z 's/\n/\\n/g')
grep -A 3 -n "^  initialRepos:" ${BASEDIR}/installed-values.yaml | grep "url:" | sed "s/\([0-9]*\).*/\1/g" | xargs -i sed -i "{}a\      caCert: \|-\n${CA_TLS_CERTIFICATE}" ${BASEDIR}/installed-values.yaml

# persistence false
sed -i "/^postgresql:/a\  primary: {persistence: {enabled: false}}\n  readReplicas: {persistence: {enabled: false}}" ${BASEDIR}/installed-values.yaml

# create namespace
kubectl create ns kubeapps

# create root ca
#kubectl create secret generic os-root-ca --from-file=ca-bundle.crt=/etc/ssl/certs/ca-bundle.crt --from-file=ca-certificates.crt=/etc/ssl/certs/ca-bundle.crt -n kubeapps

# create tls kubeapps
${PLAYCE_DIR}/playcekube/deployer/certification/01-create-ca-signed-cert.sh kubeapps.${CURRENT_CLUSTER}.${PLAYCE_DOMAIN} DNS:kubeapps.${CURRENT_CLUSTER}.${PLAYCE_DOMAIN}

# create tls secret
kubectl -n kubeapps create secret tls kubeapps-tls --cert=${PLAYCE_DIR}/playcekube/deployer/certification/certs/kubeapps.${CURRENT_CLUSTER}.${PLAYCE_DOMAIN}.crt --key=${PLAYCE_DIR}/playcekube/deployer/certification/certs/kubeapps.${CURRENT_CLUSTER}.${PLAYCE_DOMAIN}.key
#TLS_CERTIFICATE=$(sed "s/^\(.*\)/        \1/g" ${PLAYCE_DIR}/playcekube/deployer/certification/certs/kubeapps.${CURRENT_CLUSTER}.${PLAYCE_DOMAIN}.crt | sed -E "s|([/+\])|\\\\\1|g" | sed -z 's/\n/\\n/g')
#TLS_KEY=$(sed "s/^\(.*\)/        \1/g" ${PLAYCE_DIR}/playcekube/deployer/certification/certs/kubeapps.${CURRENT_CLUSTER}.${PLAYCE_DOMAIN}.key | sed -E "s|([/+\])|\\\\\1|g" | sed -z 's/\n/\\n/g')

# ingress hosts setting
grep -A 15 -n "^ingress:" ${BASEDIR}/installed-values.yaml | grep "enabled:" | sed "s/\([0-9]*\).*/\1/g" | xargs -i sed -i "{}s/enabled: .*/enabled: true/" ${BASEDIR}/installed-values.yaml
grep -A 15 -n "^ingress:" ${BASEDIR}/installed-values.yaml | grep "hostname:" | sed "s/\([0-9]*\).*/\1/g" | xargs -i sed -i "{}s/hostname: .*/hostname: kubeapps.${CURRENT_CLUSTER}.${PLAYCE_DOMAIN}/" ${BASEDIR}/installed-values.yaml
grep -A 90 -n "^ingress:" ${BASEDIR}/installed-values.yaml | grep "tls:" | sed "s/\([0-9]*\).*/\1/g" | xargs -i sed -i "{}s/tls: .*/tls: true/" ${BASEDIR}/installed-values.yaml
grep -A 90 -n "^ingress:" ${BASEDIR}/installed-values.yaml | grep "  extraTls:" | sed "s/\([0-9]*\).*/\1/g" | xargs -i sed -i "{}s/\(.*\)extraTls:.*/\1extraTls:\n\1  - hosts:\n\1      - kubeapps.${CURRENT_CLUSTER}.${PLAYCE_DOMAIN}\n\1    secretName: kubeapps-tls/" ${BASEDIR}/installed-values.yaml
#grep -A 90 -n "^ingress:" ${BASEDIR}/installed-values.yaml | grep "  secrets:" | sed "s/\([0-9]*\).*/\1/g" | xargs -i sed -i "{}s/secrets: .*/secrets:/" ${BASEDIR}/installed-values.yaml
#grep -A 90 -n "^ingress:" ${BASEDIR}/installed-values.yaml | grep "  secrets:" | sed "s/\([0-9]*\).*/\1/g" | xargs -i sed -i "{}a\    - name: kubeapps-tls\n      certificate: \|-\n${TLS_CERTIFICATE}      key: \|-\n${TLS_KEY}" ${BASEDIR}/installed-values.yaml

# install
helm install kubeapps playcekube/kubeapps -n kubeapps -f ${BASEDIR}/installed-values.yaml

