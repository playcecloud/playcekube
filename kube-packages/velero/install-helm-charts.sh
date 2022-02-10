#!/bin/sh
BASEDIR=$(dirname $(readlink -f $0))

if [ -f ${BASEDIR}/../../playcekube.conf ]; then
  . ${BASEDIR}/../../playcekube.conf
fi

# clean
helm uninstall velero -n velero
rm -rf ${BASEDIR}/installed-values.yaml
kubectl delete ns velero

# copy installed-values.yaml
cp -rp ${BASEDIR}/values.yaml ${BASEDIR}/installed-values.yaml

# current cluster name
CURRENT_CLUSTER=$(kubectl config current-context | sed "s/.*@\(.*\)/\1/")

# installed-values.yaml private registry setting
sed -i "s|repository: quay\.io/\(.*\)|repository: \1|g" ${BASEDIR}/installed-values.yaml
sed -i "s|repository: k8s\.gcr\.io/\(.*\)|repository: \1|g" ${BASEDIR}/installed-values.yaml
sed -i "s|repository: docker\.io/\(.*\)|repository: \1|g" ${BASEDIR}/installed-values.yaml
sed -i "s|repository: \(.*\)|repository: registry.${PLAYCE_DOMAIN}:5000/\1|g" ${BASEDIR}/installed-values.yaml

# provider aws
grep -A 3 -n "^configuration:" ${BASEDIR}/installed-values.yaml | grep "provider:" | sed "s/\([0-9]*\).*/\1/g" | xargs -i sed -i "{}s/provider:.*/provider: aws/" ${BASEDIR}/installed-values.yaml
sed -i "s/initContainers:/initContainers: []/g" ${BASEDIR}/installed-values.yaml

# create namespace
kubectl create ns velero

cat << EOF > ${BASEDIR}/minio-velero.cfg
[default]
aws_access_key_id=velero
aws_secret_access_key=velero123
EOF

# install
helm install velero playcekube/velero -n velero -f ${BASEDIR}/installed-values.yaml \
  --set configuration.backupStorageLocation.bucket=velero \
  --set configuration.backupStorageLocation.config.s3Url=http://minio.minio:9000 \
  --set configuration.backupStorageLocation.config.region=minio \
  --set configuration.backupStorageLocation.config.s3ForcePathStyle=true \
  --set initContainers[0].name=velero-plugin-for-aws \
  --set initContainers[0].image=registry.${PLAYCE_DOMAIN}:5000/velero/velero-plugin-for-aws:v1.3.0 \
  --set initContainers[0].volumeMounts[0].mountPath=/target \
  --set initContainers[0].volumeMounts[0].name=plugins \
  --set-file credentials.secretContents.cloud=${BASEDIR}/minio-velero.cfg

rm -rf ${BASEDIR}/minio-velero.cfg

# cli install
tar zxf ${BASEDIR}/velero-v1.7.1-linux-amd64.tar.gz
mv ${BASEDIR}/velero-v1.7.1-linux-amd64/velero /usr/local/bin/velero
rm -rf ${BASEDIR}/velero-v1.7.1-linux-amd64

velero completion bash > /etc/bash_completion.d/velero

