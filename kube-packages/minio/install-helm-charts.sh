#!/bin/sh
BASEDIR=$(dirname $(readlink -f $0))

if [ -f ${BASEDIR}/../../playcekube.conf ]; then
  . ${BASEDIR}/../../playcekube.conf
fi

# clean
helm uninstall minio -n minio
rm -rf ${BASEDIR}/installed-values.yaml
kubectl delete ns minio

# copy installed-values.yaml
cp -rp ${BASEDIR}/values.yaml ${BASEDIR}/installed-values.yaml

# current cluster name
CURRENT_CLUSTER=$(kubectl config current-context | sed "s/.*@\(.*\)/\1/")

# installed-values.yaml private registry setting
sed -i "s|repository: quay\.io/\(.*\)|repository: \1|g" ${BASEDIR}/installed-values.yaml
sed -i "s|repository: k8s\.gcr\.io/\(.*\)|repository: \1|g" ${BASEDIR}/installed-values.yaml
sed -i "s|repository: docker\.io/\(.*\)|repository: \1|g" ${BASEDIR}/installed-values.yaml
sed -i "s|repository: \(.*\)|repository: registry.${PLAYCE_DOMAIN}:5000/\1|g" ${BASEDIR}/installed-values.yaml

# secret
sed -i "s/^rootUser: .*/rootUser: admin/g" ${BASEDIR}/installed-values.yaml
sed -i "s/^rootPassword: .*/rootPassword: oscadmin/g" ${BASEDIR}/installed-values.yaml

# users
sed -i "/^users:.*/a\  - accessKey: velero\n    secretKey: velero123\n    policy: readwrite" ${BASEDIR}/installed-values.yaml

# buckets
sed -i "/^buckets:.*/a\  - name: velero\n    policy: none\n    purge: false\n    versioning: false" ${BASEDIR}/installed-values.yaml

# replicas
sed -i "s/^replicas: .*/replicas: 4/g" ${BASEDIR}/installed-values.yaml

# request memory
grep -A 3 -n "^resources:" ${BASEDIR}/installed-values.yaml | grep "memory:" | sed "s/\([0-9]*\).*/\1/g" | xargs -i sed -i "{}s/memory: .*/memory: 2Gi/" ${BASEDIR}/installed-values.yaml

# installed-values.yaml persistence volume false settting
grep -A 3 -n "persistence:" ${BASEDIR}/installed-values.yaml | grep "enabled:" | sed "s/\([0-9]*\).*/\1/g" | sort -r -n | xargs -i sed -i "{}s/enabled:.*/enabled: false/g" ${BASEDIR}/installed-values.yaml

# create tls minio
${PLAYCE_DIR}/playcekube/deployer/certification/01-create-ca-signed-cert.sh minio.${CURRENT_CLUSTER}.${PLAYCE_DOMAIN} DNS:minio.${CURRENT_CLUSTER}.${PLAYCE_DOMAIN}

# create namespace
kubectl create ns minio

# create tls secret
kubectl -n minio create secret tls minio-tls --cert=${PLAYCE_DIR}/playcekube/deployer/certification/certs/minio.${CURRENT_CLUSTER}.${PLAYCE_DOMAIN}.crt --key=${PLAYCE_DIR}/playcekube/deployer/certification/certs/minio.${CURRENT_CLUSTER}.${PLAYCE_DOMAIN}.key

# minio ingress enable
grep -A 20 -n "^consoleIngress:" ${BASEDIR}/installed-values.yaml | grep "enabled:" | sed "s/\([0-9]*\).*/\1/g" | xargs -i sed -i "{}s/enabled: .*/enabled: true/" ${BASEDIR}/installed-values.yaml
# minio ingress hosts
grep -A 20 -n "^consoleIngress:" ${BASEDIR}/installed-values.yaml | grep "hosts:" | sed "s/\([0-9]*\).*/\1/g" | xargs -i sed -i "{}s/\(.*\)hosts:.*/\1hosts:\n\1  - minio.${CURRENT_CLUSTER}.${PLAYCE_DOMAIN}/" ${BASEDIR}/installed-values.yaml
# minio ingress tls
grep -A 20 -n "^consoleIngress:" ${BASEDIR}/installed-values.yaml | grep "tls:" | sed "s/\([0-9]*\).*/\1/g" | xargs -i sed -i "{}s/\(.*\)tls: .*/\1tls:\n\1  - secretName: minio-tls\n\1    hosts:\n\1      - minio.${CURRENT_CLUSTER}.${PLAYCE_DOMAIN}/" ${BASEDIR}/installed-values.yaml

# install
helm install minio playcekube/minio -n minio -f ${BASEDIR}/installed-values.yaml

