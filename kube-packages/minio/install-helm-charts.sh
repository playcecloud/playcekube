#!/bin/bash
BASEDIR=$(dirname $(readlink -f $0))

# PLAYCE CONF
PLAYCE_DIR=/playcecloud
if [ -f ${PLAYCE_DIR}/playcecloud.conf ]; then
  . ${PLAYCE_DIR}/playcecloud.conf
fi

# chart info
CHART_NAMESPACE=playcekube
CHART_NAME=minio
CHART_VERSION=4.0.2

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

# secret
sed -i "s/^rootUser: .*/rootUser: playce-admin/g" ${BASEDIR}/installed-values.yaml
sed -i "s/^rootPassword: .*/rootPassword: vmffpdltm/g" ${BASEDIR}/installed-values.yaml

# users
sed -i "/^users:.*/a\  - accessKey: velero\n    secretKey: velero123\n    policy: readwrite" ${BASEDIR}/installed-values.yaml

# oidc config
## get keycloak kubernetes secret
REALM_KUBERNETES_SECRET=$(kubectl --context=${USING_CONTEXT} -n ${CHART_NAMESPACE} get secrets keycloak-client-secret -o jsonpath={.data.kubernetes} | base64 --decode)
if [[ "${REALM_KUBERNETES_SECRET}" != "" ]]; then
cat << EOF > yamltemp.txt
  MINIO_IDENTITY_OPENID_CONFIG_URL: https://keycloak.${USING_CLUSTER}.${PLAYCE_DOMAIN}/auth/realms/${USING_CLUSTER}/.well-known/openid-configuration
  MINIO_IDENTITY_OPENID_CLIENT_ID: kubernetes
  MINIO_IDENTITY_OPENID_CLIENT_SECRET: ${REALM_KUBERNETES_SECRET}
  MINIO_IDENTITY_OPENID_CLAIM_NAME: policy
  MINIO_IDENTITY_OPENID_KEYCLOAK_REALM: ${USING_CLUSTER}
  MINIO_IDENTITY_OPENID_KEYCLOAK_ADMIN_URL: https://keycloak.${USING_CLUSTER}.${PLAYCE_DOMAIN}/auth/admin
  MINIO_IDENTITY_OPENID_SCOPES: openid
  MINIO_IDENTITY_OPENID_COMMENT: KeyCloak
  MINIO_BROWSER_REDIRECT_URL: https://minio-console.${USING_CLUSTER}.${PLAYCE_DOMAIN}
EOF
YAML_TEMP=$(cat yamltemp.txt | sed -E "s|([/+\])|\\\\\1|g" | sed -z 's/\n/\\n/g')
rm -rf yamltemp.txt
sed -i "s/environment:.*/environment:\n${YAML_TEMP}/" ${BASEDIR}/installed-values.yaml
fi

# buckets
sed -i "/^buckets:.*/a\  - name: velero\n    policy: none\n    purge: false\n    versioning: false" ${BASEDIR}/installed-values.yaml

# replicas
sed -i "s/^replicas: .*/replicas: 4/g" ${BASEDIR}/installed-values.yaml

# request memory
grep -A 3 -n "^resources:" ${BASEDIR}/installed-values.yaml | grep "memory:" | sed "s/\([0-9]*\).*/\1/g" | xargs -i sed -i "{}s/memory: .*/memory: 2Gi/" ${BASEDIR}/installed-values.yaml

# trust certs secret
sed -i "s/trustedCertsSecret:.*/trustedCertsSecret: os-root-ca/" ${BASEDIR}/installed-values.yaml

# minio ingress enable
grep -A 20 -n "^ingress:" ${BASEDIR}/installed-values.yaml | grep "enabled:" | sed "s/\([0-9]*\).*/\1/g" | xargs -i sed -i "{}s/enabled: .*/enabled: true/" ${BASEDIR}/installed-values.yaml
# minio ingress hosts
grep -A 20 -n "^ingress:" ${BASEDIR}/installed-values.yaml | grep "hosts:" | sed "s/\([0-9]*\).*/\1/g" | xargs -i sed -i "{}s/\(.*\)hosts:.*/\1hosts:\n\1  - minio.${USING_CLUSTER}.${PLAYCE_DOMAIN}/" ${BASEDIR}/installed-values.yaml
# minio ingress tls
grep -A 20 -n "^ingress:" ${BASEDIR}/installed-values.yaml | grep "tls:" | sed "s/\([0-9]*\).*/\1/g" | xargs -i sed -i "{}s/\(.*\)tls: .*/\1tls:\n\1  - secretName: wild-tls\n\1    hosts:\n\1      - minio.${USING_CLUSTER}.${PLAYCE_DOMAIN}/" ${BASEDIR}/installed-values.yaml

grep -A 20 -n "^consoleIngress:" ${BASEDIR}/installed-values.yaml | grep "enabled:" | sed "s/\([0-9]*\).*/\1/g" | xargs -i sed -i "{}s/enabled: .*/enabled: true/" ${BASEDIR}/installed-values.yaml
# minio ingress hosts
grep -A 20 -n "^consoleIngress:" ${BASEDIR}/installed-values.yaml | grep "hosts:" | sed "s/\([0-9]*\).*/\1/g" | xargs -i sed -i "{}s/\(.*\)hosts:.*/\1hosts:\n\1  - minio-console.${USING_CLUSTER}.${PLAYCE_DOMAIN}/" ${BASEDIR}/installed-values.yaml
# minio ingress tls
grep -A 20 -n "^consoleIngress:" ${BASEDIR}/installed-values.yaml | grep "tls:" | sed "s/\([0-9]*\).*/\1/g" | xargs -i sed -i "{}s/\(.*\)tls: .*/\1tls:\n\1  - secretName: wild-tls\n\1    hosts:\n\1      - minio-console.${USING_CLUSTER}.${PLAYCE_DOMAIN}/" ${BASEDIR}/installed-values.yaml

# install
helm --kube-context=${USING_CONTEXT} upgrade -i ${CHART_NAME} playcekube/${CHART_NAME} -n ${CHART_NAMESPACE} \
 -f ${BASEDIR}/installed-values.yaml

