#!/bin/bash
BASEDIR=$(dirname $(readlink -f $0))

# PLAYCE CONF
PLAYCE_DIR=/playcecloud
if [ -f ${PLAYCE_DIR}/playcecloud.conf ]; then
  . ${PLAYCE_DIR}/playcecloud.conf
fi

# chart info
CHART_NAMESPACE=playcekube
CHART_NAME=velero
CHART_VERSION=2.30.1

# get installed-values.yaml
helm show values playcekube/${CHART_NAME} > ${BASEDIR}/installed-values.yaml

# using cluster name
USING_CONTEXT=${1}
USING_CONTEXT=${USING_CONTEXT:=$(kubectl config current-context)}
USING_CLUSTER=${USING_CONTEXT#*@}


# installed-values.yaml private registry setting
sed -i "s|repository: quay\.io/\(.*\)|repository: \1|g" ${BASEDIR}/installed-values.yaml
sed -i "s|repository: k8s\.gcr\.io/\(.*\)|repository: \1|g" ${BASEDIR}/installed-values.yaml
sed -i "s|repository: docker\.io/\(.*\)|repository: \1|g" ${BASEDIR}/installed-values.yaml
sed -i "s|repository: \(.*\)|repository: registry.local.cloud:5000/\1|g" ${BASEDIR}/installed-values.yaml

# provider aws
grep -A 3 -n "^configuration:" ${BASEDIR}/installed-values.yaml | grep "provider:" | sed "s/\([0-9]*\).*/\1/g" | xargs -i sed -i "{}s/provider:.*/provider: aws/" ${BASEDIR}/installed-values.yaml
sed -i "s/initContainers:/initContainers: []/g" ${BASEDIR}/installed-values.yaml

cat << EOF > ${BASEDIR}/minio-velero.cfg
[default]
aws_access_key_id=velero
aws_secret_access_key=velero123
EOF

# install
helm --kube-context=${USING_CONTEXT} upgrade -i ${CHART_NAME} playcekube/${CHART_NAME} -n ${CHART_NAMESPACE} \
 -f ${BASEDIR}/installed-values.yaml \
 --set configuration.backupStorageLocation.bucket=velero \
 --set configuration.backupStorageLocation.config.s3Url=http://minio.${CHART_NAMESPACE}:9000 \
 --set configuration.backupStorageLocation.config.region=minio \
 --set configuration.backupStorageLocation.config.s3ForcePathStyle=true \
 --set initContainers[0].name=velero-plugin-for-aws \
 --set initContainers[0].image=registry.local.cloud:5000/velero/velero-plugin-for-aws:v1.3.0 \
 --set initContainers[0].volumeMounts[0].mountPath=/target \
 --set initContainers[0].volumeMounts[0].name=plugins \
 --set-file credentials.secretContents.cloud=${BASEDIR}/minio-velero.cfg

rm -rf ${BASEDIR}/minio-velero.cfg

# cli install
BINARY_NAME=$(ls -vr ${BASEDIR}/chart-${CHART_VERSION}/velero-*.gz | head -n 1)
tar zxf ${BINARY_NAME}
mv velero-*-linux-amd64/velero /usr/local/bin/velero
rm -rf velero-*-linux-amd64

velero completion bash > /etc/bash_completion.d/velero
velero client config set namespace=${CHART_NAMESPACE}

# example dr backup-location
#velero backup-location create backups-dr \
#    --provider aws \
#    --bucket velero-backup-dr \
#    --config region=minio,s3ForcePathStyle=true,s3Url=https://minio.k8s2.playce.cloud

